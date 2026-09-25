part of 'cost_form_bloc.dart';

enum CostFormStatus { initial, submitting, success, failure }

final class CostFormState {
  CostFormState({
    this.isEditing = false,
    this.editCostId,
    this.name = '',
    this.amount = 0.0,
    this.amountStr = '',
    this.costType = CostType.variable,
    this.costScope = CostScope.personal,
    this.selectedCategory,
    this.availableCategories = const [],
    this.availableHouses = const [],
    DateTime? purchaseDate,
    this.selectedHouseId,
    this.members = const [],
    this.selectedPayerId,
    this.selectedPayerName,
    this.isCurrentUserAdmin = false,
    this.note = '',
    this.status = CostFormStatus.initial,
    this.createdCost,
    this.errorMessage,
  }) : purchaseDate = purchaseDate ?? DateTime.now();

  final bool isEditing;
  final String? editCostId;
  final String name;
  final double amount;
  final String amountStr;
  final CostType costType;
  final CostScope costScope;
  final CostCategory? selectedCategory;
  final List<CostCategory> availableCategories;
  final List<({String id, String name, String? avatarUrl})> availableHouses;
  final DateTime purchaseDate;
  final String? selectedHouseId;
  final List<HouseMember> members;
  final String? selectedPayerId;
  final String? selectedPayerName;
  final bool isCurrentUserAdmin;
  final String note;
  final CostFormStatus status;
  final Cost? createdCost;
  final String? errorMessage;

  bool get isSubmitting => status == CostFormStatus.submitting;
  bool get isSuccess => status == CostFormStatus.success;
  bool get isPersonal => costScope == CostScope.personal || selectedHouseId == null;
  bool get isMealPoolConflict => isPersonal && (selectedCategory?.isFood == true);
  bool get isValid => amount > 0 && !isMealPoolConflict;
  String get displayAmount => amountStr.isEmpty ? '0' : amountStr;
  ({String id, String name, String? avatarUrl})? get selectedHouse {
    if (selectedHouseId == null) return null;
    return availableHouses.where((h) => h.id == selectedHouseId).firstOrNull;
  }

  CostFormState copyWith({
    bool? isEditing,
    String? editCostId,
    String? name,
    double? amount,
    String? amountStr,
    CostType? costType,
    CostScope? costScope,
    CostCategory? selectedCategory,
    bool clearCategory = false,
    List<CostCategory>? availableCategories,
    List<({String id, String name, String? avatarUrl})>? availableHouses,
    DateTime? purchaseDate,
    String? selectedHouseId,
    bool clearHouse = false,
    List<HouseMember>? members,
    String? selectedPayerId,
    bool clearPayer = false,
    String? selectedPayerName,
    bool? isCurrentUserAdmin,
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
      amountStr: amountStr ?? this.amountStr,
      costType: costType ?? this.costType,
      costScope: costScope ?? this.costScope,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      availableCategories: availableCategories ?? this.availableCategories,
      availableHouses: availableHouses ?? this.availableHouses,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      selectedHouseId: clearHouse
          ? null
          : (selectedHouseId ?? this.selectedHouseId),
      members: members ?? this.members,
      selectedPayerId: clearPayer
          ? null
          : (selectedPayerId ?? this.selectedPayerId),
      selectedPayerName: clearPayer
          ? null
          : (selectedPayerName ?? this.selectedPayerName),
      isCurrentUserAdmin: isCurrentUserAdmin ?? this.isCurrentUserAdmin,
      note: note ?? this.note,
      status: status ?? this.status,
      createdCost: createdCost ?? this.createdCost,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
