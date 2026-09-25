part of 'cost_category_form_bloc.dart';

enum CostCategoryFormStatus { initial, submitting, success, failure }

final class CostCategoryFormState {
  const CostCategoryFormState({
    this.status = CostCategoryFormStatus.initial,
    this.name = '',
    this.selectedEmoji,
    this.selectedImageUrl,
    this.pickedImagePath,
    this.isMealCosting = false,
    this.costNature = 'variable',
    this.defaultAmount,
    this.houseId,
    this.createdCategory,
    this.errorMessage,
  });

  final CostCategoryFormStatus status;
  final String name;
  final String? selectedEmoji;
  final String? selectedImageUrl;
  final String? pickedImagePath;
  final bool isMealCosting;
  final String costNature;
  final double? defaultAmount;
  final String? houseId;
  final CostCategory? createdCategory;
  final String? errorMessage;

  bool get isSubmitting => status == CostCategoryFormStatus.submitting;
  bool get isSuccess => status == CostCategoryFormStatus.success;

  CostCategoryFormState copyWith({
    CostCategoryFormStatus? status,
    String? name,
    String? selectedEmoji,
    bool clearEmoji = false,
    String? selectedImageUrl,
    bool clearImageUrl = false,
    String? pickedImagePath,
    bool clearPickedImage = false,
    bool? isMealCosting,
    String? costNature,
    double? defaultAmount,
    bool clearDefaultAmount = false,
    String? houseId,
    CostCategory? createdCategory,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CostCategoryFormState(
      status: status ?? this.status,
      name: name ?? this.name,
      selectedEmoji: clearEmoji ? null : (selectedEmoji ?? this.selectedEmoji),
      selectedImageUrl: clearImageUrl ? null : (selectedImageUrl ?? this.selectedImageUrl),
      pickedImagePath: clearPickedImage ? null : (pickedImagePath ?? this.pickedImagePath),
      isMealCosting: isMealCosting ?? this.isMealCosting,
      costNature: costNature ?? this.costNature,
      defaultAmount: clearDefaultAmount ? null : (defaultAmount ?? this.defaultAmount),
      houseId: houseId ?? this.houseId,
      createdCategory: createdCategory ?? this.createdCategory,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
