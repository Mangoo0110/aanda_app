part of 'cost_category_form_bloc.dart';

sealed class CostCategoryFormEvent {
  const CostCategoryFormEvent();
}

final class CostCategoryNameChanged extends CostCategoryFormEvent {
  const CostCategoryNameChanged(this.name);
  final String name;
}

final class CostCategoryEmojiSelected extends CostCategoryFormEvent {
  const CostCategoryEmojiSelected(this.emoji);
  final String emoji;
}

final class CostCategoryPresetImageSelected extends CostCategoryFormEvent {
  const CostCategoryPresetImageSelected(this.imageUrl);
  final String imageUrl;
}

final class CostCategoryImageFilePicked extends CostCategoryFormEvent {
  const CostCategoryImageFilePicked(this.filePath);
  final String filePath;
}

final class CostCategoryFoodToggled extends CostCategoryFormEvent {
  const CostCategoryFoodToggled(this.isFood);
  final bool isFood;
}

final class CostCategoryNatureChanged extends CostCategoryFormEvent {
  const CostCategoryNatureChanged(this.nature);
  final String nature;
}

final class CostCategoryDefaultAmountChanged extends CostCategoryFormEvent {
  const CostCategoryDefaultAmountChanged(this.amount);
  final double? amount;
}

final class CostCategoryHouseChanged extends CostCategoryFormEvent {
  const CostCategoryHouseChanged(this.houseId);
  final String? houseId;
}

final class CostCategorySubmitted extends CostCategoryFormEvent {
  const CostCategorySubmitted();
}
