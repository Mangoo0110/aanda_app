import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aanda/src/features/dashboard/presentation/widgets/today_meals_table_card.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/entities/member_role.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';

void main() {
  final now = DateTime.now();
  final testMembers = [
    HouseMember(
      id: 'm1',
      houseId: 'h1',
      userId: 'u1',
      role: MemberRole.admin,
      joinedAt: now,
      fullName: 'Anik',
    ),
    HouseMember(
      id: 'm2',
      houseId: 'h1',
      userId: 'u2',
      role: MemberRole.member,
      joinedAt: now,
      fullName: 'Sujit',
    ),
    HouseMember(
      id: 'm3',
      houseId: 'h1',
      userId: 'u3',
      role: MemberRole.member,
      joinedAt: now,
      fullName: 'Mridul',
    ),
  ];

  final testLogs = [
    MealLog(
      id: 'l1',
      houseId: 'h1',
      cycleId: 'c1',
      userId: 'u1',
      logDate: now,
      breakfast: 1.0,
      lunch: 1.0,
      dinner: 2.0,
    ),
    MealLog(
      id: 'l2',
      houseId: 'h1',
      cycleId: 'c1',
      userId: 'u2',
      logDate: now,
      breakfast: 0.0,
      lunch: 1.0,
      dinner: 1.0,
    ),
    MealLog(
      id: 'l3',
      houseId: 'h1',
      cycleId: 'c1',
      userId: 'u3',
      logDate: now,
      breakfast: 1.0,
      lunch: 0.0,
      dinner: 1.0,
    ),
  ];

  testWidgets('TodayMealsTableCard renders columns and member rows with bracketed totals',
      (tester) async {
    bool ledgerOpened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TodayMealsTableCard(
              members: testMembers,
              mealLogs: testLogs,
              onOpenMealLog: () => ledgerOpened = true,
            ),
          ),
        ),
      ),
    );

    // Verify Title and Action
    expect(find.text("Today's Meals"), findsOneWidget);
    expect(find.text('Ledger'), findsOneWidget);

    // Verify Column Headers with bracketed totals:
    // Breakfast total: 1 + 0 + 1 = 2
    // Lunch total: 1 + 1 + 0 = 2
    // Dinner total: 2 + 1 + 1 = 4
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Breakfast(2)'), findsOneWidget);
    expect(find.text('Lunch(2)'), findsOneWidget);
    expect(find.text('Dinner(4)'), findsOneWidget);

    // Verify Member names appear as rows
    expect(find.text('Anik'), findsOneWidget);
    expect(find.text('Sujit'), findsOneWidget);
    expect(find.text('Mridul'), findsOneWidget);

    // Tap Ledger
    await tester.tap(find.text('Ledger'));
    expect(ledgerOpened, isTrue);
  });
}
