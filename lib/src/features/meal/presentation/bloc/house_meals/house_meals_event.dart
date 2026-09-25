part of 'house_meals_bloc.dart';

sealed class HouseMealsEvent {
  const HouseMealsEvent();
}

final class HouseMealsStarted extends HouseMealsEvent {
  const HouseMealsStarted();
}

final class HouseMealsRefreshRequested extends HouseMealsEvent {
  const HouseMealsRefreshRequested();
}

final class HouseMealsDateSelected extends HouseMealsEvent {
  const HouseMealsDateSelected(this.date);
  final DateTime date;
}

final class HouseMealEntryChanged extends HouseMealsEvent {
  const HouseMealEntryChanged({
    required this.userId,
    required this.logDate,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  final String userId;
  final DateTime logDate;
  final double breakfast;
  final double lunch;
  final double dinner;
}

/// Fired when the user selects a different billing cycle in the Member Log view.
final class HouseMealsCycleChanged extends HouseMealsEvent {
  const HouseMealsCycleChanged(this.sprint);
  final Sprint sprint;
}

final class HouseMealsMemberSelected extends HouseMealsEvent {
  const HouseMealsMemberSelected(this.userId);
  final String userId;
}

final class HouseMealBulkEntryChanged extends HouseMealsEvent {
  const HouseMealBulkEntryChanged({
    required this.userIds,
    required this.logDate,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  final List<String> userIds;
  final DateTime logDate;
  final double breakfast;
  final double lunch;
  final double dinner;
}
