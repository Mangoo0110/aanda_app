import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_type.dart';
import 'package:aanda/src/features/cost/domain/repo/cost_repo.dart';
import 'package:aanda/src/features/cost/domain/usecases/cost_usecases.dart';

part 'cost_form_event.dart';
part 'cost_form_state.dart';

final class CostFormBloc extends Bloc<CostFormEvent, CostFormState> {
  CostFormBloc({
    required AddCost addCost,
    required UpdateCost updateCost,
    required GetCostCategories getCostCategories,
  }) : _addCost = addCost,
       _updateCost = updateCost,
       _getCostCategories = getCostCategories,
       super(CostFormState()) {
    on<CostFormStarted>(_onStarted);
    on<CostFormScopeChanged>(_onScopeChanged);
    on<CostFormNameChanged>(_onNameChanged);
    on<CostFormAmountChanged>(_onAmountChanged);
    on<CostFormTypeChanged>(_onTypeChanged);
    on<CostFormCategoryChanged>(_onCategoryChanged);
    on<CostFormDateChanged>(_onDateChanged);
    on<CostFormHouseChanged>(_onHouseChanged);
    on<CostFormNoteChanged>(_onNoteChanged);
    on<CostFormSubmitted>(_onSubmitted);
  }

  final AddCost _addCost;
  final UpdateCost _updateCost;
  final GetCostCategories _getCostCategories;

  Future<void> _onStarted(
    CostFormStarted event,
    Emitter<CostFormState> emit,
  ) async {
    // Load categories
    final catResponse = await _getCostCategories(
      GetCostCategoriesParams(houseId: event.defaultHouseId),
    );
    final categories = catResponse.data ?? CostCategory.predefinedCategories;

    if (event.initialCost != null) {
      final c = event.initialCost!;
      final matchedCat = categories.where(
        (cat) => cat.id == c.categoryId,
      ).firstOrNull;

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
          purchaseDate: c.purchaseDate,
          selectedHouseId: c.houseId,
          note: c.note ?? '',
        ),
      );
    } else {
      emit(
        state.copyWith(
          availableCategories: categories,
          selectedHouseId: event.defaultHouseId,
          costScope: event.defaultHouseId != null ? CostScope.shared : CostScope.personal,
        ),
      );
    }
  }

  void _onScopeChanged(
    CostFormScopeChanged event,
    Emitter<CostFormState> emit,
  ) {
    emit(state.copyWith(costScope: event.scope));
  }

  void _onNameChanged(
    CostFormNameChanged event,
    Emitter<CostFormState> emit,
  ) {
    emit(state.copyWith(name: event.name, clearError: true));
  }

  void _onAmountChanged(
    CostFormAmountChanged event,
    Emitter<CostFormState> emit,
  ) {
    emit(state.copyWith(amount: event.amount, clearError: true));
  }

  void _onTypeChanged(
    CostFormTypeChanged event,
    Emitter<CostFormState> emit,
  ) {
    emit(state.copyWith(costType: event.type));
  }

  void _onCategoryChanged(
    CostFormCategoryChanged event,
    Emitter<CostFormState> emit,
  ) {
    emit(
      state.copyWith(
        selectedCategory: event.category,
        clearCategory: event.category == null,
      ),
    );
  }

  void _onDateChanged(
    CostFormDateChanged event,
    Emitter<CostFormState> emit,
  ) {
    emit(state.copyWith(purchaseDate: event.date));
  }

  void _onHouseChanged(
    CostFormHouseChanged event,
    Emitter<CostFormState> emit,
  ) {
    emit(
      state.copyWith(
        selectedHouseId: event.houseId,
        clearHouse: event.houseId == null,
      ),
    );
  }

  void _onNoteChanged(
    CostFormNoteChanged event,
    Emitter<CostFormState> emit,
  ) {
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
      final response = await _updateCost(
        UpdateCostData(
          id: state.editCostId!,
          name: state.name.trim(),
          amount: state.amount,
          costType: state.costType,
          costScope: state.costScope,
          purchaseDate: state.purchaseDate,
          houseId: state.costScope == CostScope.shared ? state.selectedHouseId : null,
          categoryId: state.selectedCategory?.id,
          categoryName: state.selectedCategory?.name,
          categoryIcon: state.selectedCategory?.icon,
          note: state.note.trim().isEmpty ? null : state.note.trim(),
        ),
      );

      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            status: CostFormStatus.success,
            createdCost: response.data,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: CostFormStatus.failure,
            errorMessage: response.message,
          ),
        );
      }
    } else {
      final response = await _addCost(
        CreateCostData(
          name: state.name.trim(),
          amount: state.amount,
          costType: state.costType,
          costScope: state.costScope,
          purchaseDate: state.purchaseDate,
          houseId: state.costScope == CostScope.shared ? state.selectedHouseId : null,
          categoryId: state.selectedCategory?.id,
          categoryName: state.selectedCategory?.name,
          categoryIcon: state.selectedCategory?.icon,
          note: state.note.trim().isEmpty ? null : state.note.trim(),
        ),
      );

      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            status: CostFormStatus.success,
            createdCost: response.data,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: CostFormStatus.failure,
            errorMessage: response.message,
          ),
        );
      }
    }
  }
}
