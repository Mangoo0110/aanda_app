import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_type.dart';
import 'package:aanda/src/features/cost/domain/repo/cost_repo.dart';
import 'package:aanda/src/features/cost/domain/usecases/cost_usecases.dart';
import 'package:aanda/src/features/house/data/models/house_member_model.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/usecases/get_house_members.dart';

part 'cost_form_event.dart';
part 'cost_form_state.dart';

final class CostFormBloc extends Bloc<CostFormEvent, CostFormState> {
  CostFormBloc({
    required AddCost addCost,
    required UpdateCost updateCost,
    required GetCostCategories getCostCategories,
    GetHouseMembers? getHouseMembers,
  })  : _addCost = addCost,
        _updateCost = updateCost,
        _getCostCategories = getCostCategories,
        _getHouseMembers = getHouseMembers,
        super(CostFormState()) {
    on<CostFormStarted>(_onStarted);
    on<CostFormScopeChanged>(_onScopeChanged);
    on<CostFormReferenceChanged>(_onReferenceChanged);
    on<CostFormNameChanged>(_onNameChanged);
    on<CostFormAmountChanged>(_onAmountChanged);
    on<CostFormTypeChanged>(_onTypeChanged);
    on<CostFormCategoryChanged>(_onCategoryChanged);
    on<CostFormDateChanged>(_onDateChanged);
    on<CostFormHouseChanged>(_onHouseChanged);
    on<CostFormPayerChanged>(_onPayerChanged);
    on<CostFormNoteChanged>(_onNoteChanged);
    on<CostFormSubmitted>(_onSubmitted);
  }

  final AddCost _addCost;
  final UpdateCost _updateCost;
  final GetCostCategories _getCostCategories;
  final GetHouseMembers? _getHouseMembers;

  Future<
      ({
        List<HouseMember> members,
        bool isAdmin,
        String currentUserId,
        HouseMember? currentMember
      })> _fetchHouseMembers(String houseId) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    List<HouseMember> members = const [];

    if (_getHouseMembers != null) {
      final res = await handleFutureRequest<List<HouseMember>>(
        request: () => _getHouseMembers(houseId),
        debugger: ControllerDebugger(),
      );
      if (res != null) members = res;
    }

    if (members.isEmpty) {
      try {
        final res = await Supabase.instance.client
            .from('expense_account_members')
            .select(
                'id, house_id, user_id, role, joined_at, profiles(username, full_name, avatar_url)')
            .eq('house_id', houseId);
        members =
            (res as List).map((r) => HouseMemberModel.fromJson(r)).toList();
      } catch (_) {}
    }

    final currentMember =
        members.where((m) => m.userId == currentUserId).firstOrNull;
    final isAdmin = currentMember?.isAdmin ?? false;

    return (
      members: members,
      isAdmin: isAdmin,
      currentUserId: currentUserId,
      currentMember: currentMember,
    );
  }

  Future<void> _onStarted(
    CostFormStarted event,
    Emitter<CostFormState> emit,
  ) async {
    // Load categories
    final categories =
        await handleFutureRequest<List<CostCategory>>(
          request: () => _getCostCategories(
            GetCostCategoriesParams(houseId: event.defaultHouseId),
          ),
          debugger: ControllerDebugger(),
        ) ??
        CostCategory.predefinedCategories;

    // Load user's houses
    List<({String id, String name})> houses = const [];
    try {
      final res = await Supabase.instance.client
          .from('expense_accounts')
          .select('id, name')
          .order('name');
      houses = (res as List)
          .map((h) => (id: h['id'] as String, name: h['name'] as String))
          .toList();
    } catch (_) {}

    final initialHouseId = event.initialCost?.houseId ??
        event.defaultHouseId ??
        (houses.isNotEmpty ? houses.first.id : null);

    List<HouseMember> initialMembers = const [];
    bool isUserAdmin = false;
    String? initialPayerId = Supabase.instance.client.auth.currentUser?.id;
    String? initialPayerName = 'You';

    if (initialHouseId != null) {
      final info = await _fetchHouseMembers(initialHouseId);
      initialMembers = info.members;
      isUserAdmin = info.isAdmin;

      if (event.initialCost != null) {
        final matchedMember = initialMembers
            .where((m) => m.userId == event.initialCost!.paidBy)
            .firstOrNull;
        initialPayerId = event.initialCost!.paidBy;
        initialPayerName = matchedMember != null
            ? (matchedMember.userId == info.currentUserId
                ? '${matchedMember.displayName} (You)'
                : matchedMember.displayName)
            : (event.initialCost!.payerName ?? 'You');
      } else {
        final cur = info.currentMember ?? initialMembers.firstOrNull;
        if (cur != null) {
          initialPayerId = cur.userId;
          initialPayerName = cur.userId == info.currentUserId
              ? '${cur.displayName} (You)'
              : cur.displayName;
        }
      }
    }

    if (event.initialCost != null) {
      final c = event.initialCost!;
      final matchedCat = categories
          .where((cat) => cat.id == c.categoryId)
          .firstOrNull;

      emit(
        state.copyWith(
          isEditing: true,
          editCostId: c.id,
          name: c.name,
          amount: c.amount,
          costType: c.costType,
          costScope: c.costScope,
          selectedCategory: matchedCat,
          availableCategories: categories,
          availableHouses: houses,
          purchaseDate: c.purchaseDate,
          selectedHouseId: c.houseId,
          members: initialMembers,
          selectedPayerId: initialPayerId,
          selectedPayerName: initialPayerName,
          isCurrentUserAdmin: isUserAdmin,
          note: c.note ?? '',
        ),
      );
    } else {
      CostCategory? targetCategory;
      if (event.initialCategory != null) {
        targetCategory = categories
            .where((cat) =>
                cat.id == event.initialCategory!.id ||
                cat.name.trim().toLowerCase() ==
                    event.initialCategory!.name.trim().toLowerCase())
            .firstOrNull ??
            event.initialCategory;
      } else if (event.initialCategoryId != null) {
        targetCategory = categories
            .where((cat) =>
                cat.id == event.initialCategoryId ||
                cat.name.trim().toLowerCase() ==
                    event.initialCategoryId!.trim().toLowerCase())
            .firstOrNull;
      }
      targetCategory ??= categories.firstOrNull;

      final costType = (targetCategory?.costNature == 'fixed')
          ? CostType.fixed
          : CostType.variable;

      final initialAmount = (targetCategory?.defaultAmount != null &&
              targetCategory!.defaultAmount! > 0)
          ? targetCategory.defaultAmount!
          : 0.0;

      final effectiveCategories = (targetCategory != null &&
              !categories.any((c) => c.id == targetCategory!.id))
          ? [targetCategory, ...categories]
          : categories;

      emit(
        state.copyWith(
          availableCategories: effectiveCategories,
          availableHouses: houses,
          selectedCategory: targetCategory,
          costType: costType,
          amount: initialAmount > 0 ? initialAmount : null,
          selectedHouseId: initialHouseId,
          costScope: initialHouseId != null
              ? CostScope.shared
              : CostScope.personal,
          members: initialMembers,
          selectedPayerId: initialPayerId,
          selectedPayerName: initialPayerName,
          isCurrentUserAdmin: isUserAdmin,
        ),
      );
    }
  }

  void _onReferenceChanged(
    CostFormReferenceChanged event,
    Emitter<CostFormState> emit,
  ) {
    emit(
      state.copyWith(
        costScope: event.scope,
        selectedHouseId: event.houseId,
        clearHouse: event.houseId == null,
      ),
    );
  }

  void _onScopeChanged(
    CostFormScopeChanged event,
    Emitter<CostFormState> emit,
  ) {
    emit(state.copyWith(costScope: event.scope));
  }

  void _onNameChanged(CostFormNameChanged event, Emitter<CostFormState> emit) {
    emit(state.copyWith(name: event.name, clearError: true));
  }

  void _onAmountChanged(
    CostFormAmountChanged event,
    Emitter<CostFormState> emit,
  ) {
    emit(state.copyWith(amount: event.amount, clearError: true));
  }

  void _onTypeChanged(CostFormTypeChanged event, Emitter<CostFormState> emit) {
    emit(state.copyWith(costType: event.type));
  }

  void _onCategoryChanged(
    CostFormCategoryChanged event,
    Emitter<CostFormState> emit,
  ) {
    final newCostType = event.category?.costNature == 'fixed'
        ? CostType.fixed
        : (event.category?.costNature == 'variable'
            ? CostType.variable
            : state.costType);
    emit(
      state.copyWith(
        selectedCategory: event.category,
        costType: newCostType,
        clearCategory: event.category == null,
      ),
    );
  }

  void _onDateChanged(CostFormDateChanged event, Emitter<CostFormState> emit) {
    emit(state.copyWith(purchaseDate: event.date));
  }

  Future<void> _onHouseChanged(
    CostFormHouseChanged event,
    Emitter<CostFormState> emit,
  ) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (event.houseId == null) {
      emit(
        state.copyWith(
          selectedHouseId: null,
          clearHouse: true,
          costScope: CostScope.personal,
          members: const [],
          selectedPayerId: currentUserId,
          selectedPayerName: 'You',
          isCurrentUserAdmin: false,
        ),
      );
      return;
    }

    final info = await _fetchHouseMembers(event.houseId!);
    final defaultPayer = info.currentMember ?? info.members.firstOrNull;

    emit(
      state.copyWith(
        selectedHouseId: event.houseId,
        costScope: CostScope.shared,
        members: info.members,
        isCurrentUserAdmin: info.isAdmin,
        selectedPayerId: defaultPayer?.userId ?? currentUserId,
        selectedPayerName: defaultPayer != null
            ? (defaultPayer.userId == currentUserId
                ? '${defaultPayer.displayName} (You)'
                : defaultPayer.displayName)
            : 'You',
      ),
    );
  }

  void _onPayerChanged(
    CostFormPayerChanged event,
    Emitter<CostFormState> emit,
  ) {
    emit(
      state.copyWith(
        selectedPayerId: event.payerId,
        selectedPayerName: event.payerName,
      ),
    );
  }

  void _onNoteChanged(CostFormNoteChanged event, Emitter<CostFormState> emit) {
    emit(state.copyWith(note: event.note));
  }

  Future<void> _onSubmitted(
    CostFormSubmitted event,
    Emitter<CostFormState> emit,
  ) async {
    if (!state.isValid) {
      emit(
        state.copyWith(
          status: CostFormStatus.failure,
          errorMessage: 'Please enter a valid title and amount.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: CostFormStatus.submitting, clearError: true));

    if (state.isEditing && state.editCostId != null) {
      final updatedCost = await handleFutureRequest<Cost>(
        request: () => _updateCost(
          UpdateCostData(
            id: state.editCostId!,
            name: state.name.trim(),
            amount: state.amount,
            costType: state.costType,
            costScope: state.costScope,
            purchaseDate: state.purchaseDate,
            houseId: state.costScope == CostScope.shared
                ? state.selectedHouseId
                : null,
            categoryId: state.selectedCategory?.id,
            categoryName: state.selectedCategory?.name,
            categoryIcon: state.selectedCategory?.icon,
            note: state.note.trim().isEmpty ? null : state.note.trim(),
            paidBy: state.selectedPayerId,
          ),
        ),
        debugger: ControllerDebugger(),
        onError: (failure) {
          emit(
            state.copyWith(
              status: CostFormStatus.failure,
              errorMessage: failure.message,
            ),
          );
        },
        onSuccess: (cost) {
          emit(
            state.copyWith(status: CostFormStatus.success, createdCost: cost),
          );
        },
      );

      if (updatedCost == null && state.status == CostFormStatus.submitting) {
        emit(state.copyWith(status: CostFormStatus.failure));
      }
    } else {
      final newCost = await handleFutureRequest<Cost>(
        request: () => _addCost(
          CreateCostData(
            name: state.name.trim(),
            amount: state.amount,
            costType: state.costType,
            costScope: state.costScope,
            purchaseDate: state.purchaseDate,
            houseId: state.costScope == CostScope.shared
                ? state.selectedHouseId
                : null,
            categoryId: state.selectedCategory?.id,
            categoryName: state.selectedCategory?.name,
            categoryIcon: state.selectedCategory?.icon,
            note: state.note.trim().isEmpty ? null : state.note.trim(),
            paidBy: state.selectedPayerId,
          ),
        ),
        debugger: ControllerDebugger(),
        onError: (failure) {
          emit(
            state.copyWith(
              status: CostFormStatus.failure,
              errorMessage: failure.message,
            ),
          );
        },
        onSuccess: (cost) {
          emit(
            state.copyWith(status: CostFormStatus.success, createdCost: cost),
          );
        },
      );

      if (newCost == null && state.status == CostFormStatus.submitting) {
        emit(state.copyWith(status: CostFormStatus.failure));
      }
    }
  }
}
