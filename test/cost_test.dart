import 'package:flutter_test/flutter_test.dart';
import 'package:aanda/src/features/cost/data/models/cost_model.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_type.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_feed/cost_feed_bloc.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_form/cost_form_bloc.dart';

void main() {
  group('CostModel', () {
    test('deserializes personal cost correctly', () {
      final json = {
        'id': 'c1',
        'name': 'Lunch',
        'amount': 250.50,
        'cost_type': 'variable',
        'cost_scope': 'personal',
        'paid_by': 'u1',
        'purchase_date': '2026-09-15',
        'created_at': '2026-09-15T12:00:00Z',
        'expense_account_id': null,
        'cycle_id': null,
        'category_id': 'predefined_food',
        'note': 'Quick meal',
        'profiles': {'username': 'anik', 'full_name': 'Anik Saha'},
        'cost_categories': {'name': 'Food & Dining', 'icon': 'restaurant'},
      };

      final cost = CostModel.fromJson(json);

      expect(cost.id, 'c1');
      expect(cost.name, 'Lunch');
      expect(cost.amount, 250.50);
      expect(cost.isPersonal, isTrue);
      expect(cost.isShared, isFalse);
      expect(cost.costType, CostType.variable);
      expect(cost.payerName, 'Anik Saha');
      expect(cost.categoryName, 'Food & Dining');
      expect(cost.categoryIcon, 'restaurant');
      expect(cost.houseId, isNull);
    });

    test('deserializes shared house cost correctly', () {
      final json = {
        'id': 'c2',
        'name': 'Electricity Bill',
        'amount': 3200.0,
        'cost_type': 'fixed',
        'cost_scope': 'shared',
        'paid_by': 'u2',
        'purchase_date': '2026-09-10',
        'created_at': '2026-09-10T09:30:00Z',
        'expense_account_id': 'h1',
        'cycle_id': 'cycle1',
        'category_id': 'cat_custom',
        'note': null,
        'profiles': {'username': 'rahim', 'full_name': 'Rahim Khan'},
        'cost_categories': {'name': 'Utilities', 'icon': 'flash_on'},
      };

      final cost = CostModel.fromJson(json);

      expect(cost.id, 'c2');
      expect(cost.name, 'Electricity Bill');
      expect(cost.amount, 3200.0);
      expect(cost.isPersonal, isFalse);
      expect(cost.isShared, isTrue);
      expect(cost.costType, CostType.fixed);
      expect(cost.payerName, 'Rahim Khan');
      expect(cost.categoryName, 'Utilities');
      expect(cost.houseId, 'h1');
      expect(cost.cycleId, 'cycle1');
    });
  });

  group('CostFeedState', () {
    test('computes total, personal, and shared aggregations', () {
      final cost1 = Cost(
        id: '1',
        name: 'Groceries',
        amount: 500.0,
        costType: CostType.variable,
        costScope: CostScope.personal,
        paidBy: 'u1',
        purchaseDate: DateTime(2026, 9, 15),
        createdAt: DateTime(2026, 9, 15),
      );

      final cost2 = Cost(
        id: '2',
        name: 'Internet',
        amount: 1000.0,
        costType: CostType.fixed,
        costScope: CostScope.shared,
        paidBy: 'u1',
        purchaseDate: DateTime(2026, 9, 15),
        createdAt: DateTime(2026, 9, 15),
        houseId: 'h1',
      );

      final state = CostFeedState(costs: [cost1, cost2]);

      expect(state.totalSpent, 1500.0);
      expect(state.personalSpent, 500.0);
      expect(state.sharedSpent, 1000.0);
      expect(state.myTotalSpent('u1'), 1500.0);
      expect(state.myPersonalSpent('u1'), 500.0);
      expect(state.mySharedSpent('u1'), 1000.0);
      expect(state.myRecentCosts('u1').length, 1);
    });

    test('filters displayCosts by selectedPayerId', () {
      final cost1 = Cost(
        id: '1',
        name: 'Groceries',
        amount: 500.0,
        costType: CostType.variable,
        costScope: CostScope.personal,
        paidBy: 'u1',
        payerName: 'User 1',
        purchaseDate: DateTime(2026, 9, 15),
        createdAt: DateTime(2026, 9, 15),
      );
      final cost2 = Cost(
        id: '2',
        name: 'Internet',
        amount: 1000.0,
        costType: CostType.fixed,
        costScope: CostScope.shared,
        paidBy: 'u2',
        payerName: 'User 2',
        purchaseDate: DateTime(2026, 9, 15),
        createdAt: DateTime(2026, 9, 15),
      );

      final state = CostFeedState(costs: [cost1, cost2], selectedPayerId: 'u2');

      expect(state.displayCosts.length, 1);
      expect(state.displayCosts.first.id, '2');
      expect(state.uniquePayers.length, 2);
    });
  });

  group('CostFormState - Meal Pool Conflict', () {
    const mealPoolCategory = CostCategory(
      id: 'cat_food',
      name: 'Bazar / Food',
      icon: 'restaurant',
      isFood: true,
    );

    const regularCategory = CostCategory(
      id: 'cat_rent',
      name: 'Rent',
      icon: 'home',
      isFood: false,
    );

    test('flags isMealPoolConflict when personal scope has meal pool category', () {
      final state = CostFormState(
        costScope: CostScope.personal,
        selectedHouseId: null,
        selectedCategory: mealPoolCategory,
        amount: 500,
      );

      expect(state.isPersonal, isTrue);
      expect(state.isMealPoolConflict, isTrue);
      expect(state.isValid, isFalse);
    });

    test('allows meal pool category for shared house scope', () {
      final state = CostFormState(
        costScope: CostScope.shared,
        selectedHouseId: 'house_123',
        selectedCategory: mealPoolCategory,
        amount: 500,
      );

      expect(state.isPersonal, isFalse);
      expect(state.isMealPoolConflict, isFalse);
      expect(state.isValid, isTrue);
    });

    test('allows regular non-food category for personal scope', () {
      final state = CostFormState(
        costScope: CostScope.personal,
        selectedHouseId: null,
        selectedCategory: regularCategory,
        amount: 500,
      );

      expect(state.isPersonal, isTrue);
      expect(state.isMealPoolConflict, isFalse);
      expect(state.isValid, isTrue);
    });
  });
}

