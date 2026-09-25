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
    on<CostFormKeypadPressed>(_onKeypadPressed);
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
                'id, expense_account_id, user_id, role, joined_at, profiles(username, full_name, avatar_url)')
            .eq('expense_account_id', houseId);
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
    List<({String id, String name, String? avatarUrl})> houses = const [];
    try {
      final res = await Supabase.instance.client
          .from('expense_accounts')
          .select('id, name, avatar_url')
          .order('name');
      houses = (res as List)
          .map((h) => (
                id: h['id'] as String,
                name: h['name'] as String,
                avatarUrl: h['avatar_url'] as String?,
              ))
          .toList();
    } catch (_) {}
    final isExplicitlyPersonal = event.initialScope == CostScope.personal;
    final String? initialHouseId;
    if (event.initialCost != null) {
      initialHouseId = event.initialCost!.houseId;
    } else if (isExplicitlyPersonal) {
      initialHouseId = null;
    } else if (event.defaultHouseId != null) {
      initialHouseId = event.defaultHouseId;
    } else {
      initialHouseId = houses.isNotEmpty ? houses.first.id : null;
    }

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
      final amountStr = c.amount.toStringAsFixed(
        c.amount.truncateToDouble() == c.amount ? 0 : 2,
      );

      emit(
        state.copyWith(
          isEditing: true,
          editCostId: c.id,
          name: c.name,
          amount: c.amount,
          amountStr: amountStr,
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
          errorMessage: ((c.houseId == null || c.costScope == CostScope.personal) &&
                  matchedCat?.isFood == true)
              ? 'This expense is in a personal account but has meal pool category "${matchedCat?.name}". Meal pooling is only for shared houses. Please change category.'
              : null,
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

      final isPersonalCost = initialHouseId == null || isExplicitlyPersonal;
      if (isPersonalCost) {
        targetCategory ??= categories.where((c) => !c.isFood).firstOrNull ??
            categories.firstOrNull;
      } else {
        targetCategory ??= categories.firstOrNull;
      }

      final costType = (targetCategory?.costNature == 'fixed')
          ? CostType.fixed
          : CostType.variable;

      final initialAmount = (targetCategory?.defaultAmount != null &&
              targetCategory!.defaultAmount! > 0)
          ? targetCategory.defaultAmount!
          : 0.0;
      final initialAmountStr = initialAmount > 0
          ? (initialAmount % 1 == 0
              ? initialAmount.toInt().toString()
              : initialAmount.toString())
          : '';

      final effectiveCategories = (targetCategory != null &&
              !categories.any((c) => c.id == targetCategory!.id))
          ? [targetCategory, ...categories]
          : categories;

      final hasMealConflict = isPersonalCost && targetCategory?.isFood == true;

      emit(
        state.copyWith(
          availableCategories: effectiveCategories,
          availableHouses: houses,
          selectedCategory: targetCategory,
          costType: costType,
          amount: initialAmount,
          amountStr: initialAmountStr,
          selectedHouseId: initialHouseId,
          costScope: (initialHouseId != null && !isExplicitlyPersonal)
              ? CostScope.shared
              : CostScope.personal,
          members: initialMembers,
          selectedPayerId: initialPayerId,
          selectedPayerName: initialPayerName,
          isCurrentUserAdmin: isUserAdmin,
          errorMessage: hasMealConflict
              ? 'Meal pool category "${targetCategory?.name}" cannot be used for personal expenses. Please select another category.'
              : null,
        ),
      );
    }
  }

  void _onReferenceChanged(
    CostFormReferenceChanged event,
    Emitter<CostFormState> emit,
  ) {
    final isPersonal =
        event.scope == CostScope.personal || event.houseId == null;
    final hasMealPoolConflict =
        isPersonal && (state.selectedCategory?.isFood == true);

    emit(
      state.copyWith(
        costScope: event.scope,
        selectedHouseId: event.houseId,
        clearHouse: event.houseId == null,
        errorMessage: hasMealPoolConflict
            ? 'Meal pool category "${state.selectedCategory?.name}" cannot be used for personal expenses. Please change category.'
            : null,
      ),
    );
  }

  void _onScopeChanged(
    CostFormScopeChanged event,
    Emitter<CostFormState> emit,
  ) {
    final isPersonal =
        event.scope == CostScope.personal || state.selectedHouseId == null;
    final hasMealPoolConflict =
        isPersonal && (state.selectedCategory?.isFood == true);

    emit(
      state.copyWith(
        costScope: event.scope,
        errorMessage: hasMealPoolConflict
            ? 'Meal pool category "${state.selectedCategory?.name}" cannot be used for personal expenses. Please change category.'
            : null,
      ),
    );
  }

  void _onNameChanged(CostFormNameChanged event, Emitter<CostFormState> emit) {
    emit(state.copyWith(name: event.name, clearError: true));
  }

  void _onAmountChanged(
    CostFormAmountChanged event,
    Emitter<CostFormState> emit,
  ) {
    final amt = event.amount;
    final str = amt % 1 == 0 ? amt.toInt().toString() : amt.toString();
    emit(state.copyWith(amount: amt, amountStr: str, clearError: true));
  }

  void _onTypeChanged(CostFormTypeChanged event, Emitter<CostFormState> emit) {
    emit(state.copyWith(costType: event.type));
  }

  void _onCategoryChanged(
    CostFormCategoryChanged event,
    Emitter<CostFormState> emit,
  ) {
    final isPersonal =
        state.costScope == CostScope.personal || state.selectedHouseId == null;
    if (isPersonal && event.category?.isFood == true) {
      emit(
        state.copyWith(
          errorMessage:
              'Meal pool category "${event.category?.name}" cannot be selected for personal accounts. Meal pooling is only for shared houses.',
        ),
      );
      return;
    }

    final newCostType = event.category?.costNature == 'fixed'
        ? CostType.fixed
        : (event.category?.costNature == 'variable'
            ? CostType.variable
            : state.costType);
    var amount = state.amount;
    var amountStr = state.amountStr;
    if (event.category != null &&
        event.category!.costNature != 'variable' &&
        event.category!.defaultAmount != null &&
        event.category!.defaultAmount! > 0) {
      final amt = event.category!.defaultAmount!;
      amount = amt;
      amountStr = amt % 1 == 0 ? amt.toInt().toString() : amt.toString();
    }
    emit(
      state.copyWith(
        selectedCategory: event.category,
        costType: newCostType,
        amount: amount,
        amountStr: amountStr,
        clearCategory: event.category == null,
        clearError: true,
      ),
    );
  }

  void _onKeypadPressed(
    CostFormKeypadPressed event,
    Emitter<CostFormState> emit,
  ) {
    var str = state.amountStr;
    final key = event.key;

    if (key == '⌫') {
      if (str.isNotEmpty) {
        str = str.substring(0, str.length - 1);
        if (str.isEmpty) str = '0';
      }
    } else if (key == '.') {
      if (!str.contains('.')) {
        str = str.isEmpty ? '0.' : '$str.';
      }
    } else if (key == '00') {
      if (str != '0' && str.isNotEmpty) {
        str += '00';
      }
    } else {
      // Digits 0-9
      if (str == '0') {
        str = key;
      } else {
        if (str.contains('.')) {
          final parts = str.split('.');
          if (parts.length > 1 && parts[1].length >= 2) return;
        }
        if (str.length < 9) {
          str += key;
        }
      }
    }

    final val = double.tryParse(str) ?? 0.0;
    emit(state.copyWith(amountStr: str, amount: val, clearError: true));
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
    final effectiveName = state.name.trim().isNotEmpty
        ? state.name.trim()
        : (state.note.trim().isNotEmpty
            ? state.note.trim()
            : (state.selectedCategory?.name ?? 'Expense'));

    if (state.isMealPoolConflict) {
      emit(
        state.copyWith(
          status: CostFormStatus.failure,
          errorMessage:
              'Meal pool category "${state.selectedCategory?.name}" cannot be used for personal expenses. Meal pooling is only for shared houses with meal tracking. Please change the category.',
        ),
      );
      return;
    }

    if (state.amount <= 0) {
      emit(
        state.copyWith(
          status: CostFormStatus.failure,
          errorMessage: 'Please enter an amount greater than 0.',
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
            name: effectiveName,
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
            name: effectiveName,
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
