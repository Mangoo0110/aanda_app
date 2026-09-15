part of 'cost_form_bloc.dart';

enum CostFormStatus { initial, submitting, success, failure }

final class CostFormState {
  CostFormState({
    this.isEditing = false,
    this.editCostId,
    this.name = '',
    this.amount = 0.0,
    this.costType = CostType.variable,
    this.costScope = CostScope.personal,
    this.selectedCategory,
    this.availableCategories = const [],
    DateTime? purchaseDate,
    this.selectedHouseId,
    this.note = '',
    this.status = CostFormStatus.initial,
    this.createdCost,
    this.errorMessage,
  }) : purchaseDate = purchaseDate ?? DateTime.now();

  final bool isEditing;
  final String? editCostId;
  final String name;
  final double amount;
  final CostType costType;
  final CostScope costScope;
  final CostCategory? selectedCategory;
  final List<CostCategory> availableCategories;
  final DateTime purchaseDate;
  final String? selectedHouseId;
  final String note;
  final CostFormStatus status;
  final Cost? createdCost;
  final String? errorMessage;

  bool get isSubmitting => status == CostFormStatus.submitting;
  bool get isSuccess => status == CostFormStatus.success;
  bool get isValid => name.trim().isNotEmpty && amount > 0;

  CostFormState copyWith({
    bool? isEditing,
    String? editCostId,
    String? name,
    double? amount,
    CostType? costType,
    CostScope? costScope,
    CostCategory? selectedCategory,
    bool clearCategory = false,
    List<CostCategory>? availableCategories,
    DateTime? purchaseDate,
    String? selectedHouseId,
    bool clearHouse = false,
    String? note,
    CostFormStatus? status,
    Cost? createdCost,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CostFormState(
      isEditing: isEditing ?? this.isEditing,
      editCostId: editCostId ?? this.editCostId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      costType: costType ?? this.costType,
      costScope: costScope ?? this.costScope,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      availableCategories: availableCategories ?? this.availableCategories,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      selectedHouseId:
          clearHouse ? null : (selectedHouseId ?? this.selectedHouseId),
      note: note ?? this.note,
      status: status ?? this.status,
      createdCost: createdCost ?? this.createdCost,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
