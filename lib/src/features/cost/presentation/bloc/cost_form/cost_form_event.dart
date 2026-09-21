part of 'cost_form_bloc.dart';

sealed class CostFormEvent {
  const CostFormEvent();
}

final class CostFormStarted extends CostFormEvent {
  const CostFormStarted({
    this.initialCost,
    this.initialCategory,
    this.initialCategoryId,
    this.defaultHouseId,
  });
  final Cost? initialCost;
  final CostCategory? initialCategory;
  final String? initialCategoryId;
  final String? defaultHouseId;
}

final class CostFormScopeChanged extends CostFormEvent {
  const CostFormScopeChanged(this.scope);
  final CostScope scope;
}

final class CostFormReferenceChanged extends CostFormEvent {
  const CostFormReferenceChanged({required this.scope, this.houseId});
  final CostScope scope;
  final String? houseId;
}

final class CostFormNameChanged extends CostFormEvent {
  const CostFormNameChanged(this.name);
  final String name;
}

final class CostFormAmountChanged extends CostFormEvent {
  const CostFormAmountChanged(this.amount);
  final double amount;
}

final class CostFormTypeChanged extends CostFormEvent {
  const CostFormTypeChanged(this.type);
  final CostType type;
}

final class CostFormCategoryChanged extends CostFormEvent {
  const CostFormCategoryChanged(this.category);
  final CostCategory? category;
}

final class CostFormDateChanged extends CostFormEvent {
  const CostFormDateChanged(this.date);
  final DateTime date;
}

final class CostFormHouseChanged extends CostFormEvent {
  const CostFormHouseChanged(this.houseId);
  final String? houseId;
}

final class CostFormNoteChanged extends CostFormEvent {
  const CostFormNoteChanged(this.note);
  final String note;
}

final class CostFormPayerChanged extends CostFormEvent {
  const CostFormPayerChanged({required this.payerId, required this.payerName});
  final String payerId;
  final String payerName;
}

final class CostFormSubmitted extends CostFormEvent {
  const CostFormSubmitted();
}
