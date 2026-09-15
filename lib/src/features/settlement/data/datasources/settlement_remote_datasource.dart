import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/features/house/data/models/house_member_model.dart';
import 'package:aanda/src/features/settlement/data/models/settlement_model.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';

class SettlementRemoteDatasource {
  const SettlementRemoteDatasource({required SupabaseClient supabase})
      : _supabase = supabase;

  final SupabaseClient _supabase;

  Future<Settlement> computeSettlement({
    required String cycleId,
    DateTime? calculationDate,
    bool save = false,
  }) async {
    final effectiveCutoff = calculationDate ?? DateTime.now();
    final cutoffIso = effectiveCutoff.toIso8601String().substring(0, 10);

    // 1. Try edge function first
    try {
      final res = await _supabase.functions.invoke(
        'compute-settlement',
        body: {
          'cycle_id': cycleId,
          'calculation_date': cutoffIso,
          'save': save,
        },
      );

      if (res.status == 200 && res.data != null) {
        final payload = res.data is Map && res.data['data'] != null
            ? res.data['data'] as Map<String, dynamic>
            : res.data as Map<String, dynamic>;
        return SettlementModel.fromJson(payload);
      }
    } catch (_) {
      // Fallback to local calculation
    }

    // 2. Direct Supabase query calculation fallback
    return _computeSettlementLocally(
      cycleId: cycleId,
      calculationDate: effectiveCutoff,
      save: save,
    );
  }

  Future<Settlement> _computeSettlementLocally({
    required String cycleId,
    required DateTime calculationDate,
    bool save = false,
  }) async {
    final cycleData = await _supabase
        .from('billing_cycles')
        .select()
        .eq('id', cycleId)
        .single();

    final houseId = cycleData['house_id'] as String;
    final startDate = cycleData['start_date'] as String;
    final isClosed = cycleData['status'] == 'closed';
    final effectiveEndDate = isClosed
        ? (cycleData['end_date'] as String? ?? calculationDate.toIso8601String().substring(0, 10))
        : calculationDate.toIso8601String().substring(0, 10);

    final bw = (cycleData['breakfast_weight'] as num?)?.toDouble() ?? 1.0;
    final lw = (cycleData['lunch_weight'] as num?)?.toDouble() ?? 1.0;
    final dw = (cycleData['dinner_weight'] as num?)?.toDouble() ?? 1.0;

    // Fetch members
    final membersData = await _supabase
        .from('house_members')
        .select('*, profiles(id, username, full_name, avatar_url)')
        .eq('house_id', houseId);
    final members = (membersData as List<dynamic>)
        .map((e) => HouseMemberModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Fetch shared costs up to effectiveEndDate
    final costsData = await _supabase
        .from('costs')
        .select('*, cost_categories(id, name, is_food)')
        .eq('house_id', houseId)
        .eq('cost_scope', 'shared')
        .gte('purchase_date', startDate)
        .lte('purchase_date', effectiveEndDate);

    // Fetch meal logs up to effectiveEndDate
    final mealLogsData = await _supabase
        .from('meal_logs')
        .select()
        .eq('house_id', houseId)
        .eq('cycle_id', cycleId)
        .lte('log_date', effectiveEndDate);

    // Aggregate meal counts per user
    final Map<String, double> rawMeals = {};
    final Map<String, double> weightedMeals = {};
    for (final raw in (mealLogsData as List<dynamic>)) {
      final log = raw as Map<String, dynamic>;
      final uid = log['user_id'] as String;
      final b = (log['breakfast'] as num?)?.toDouble() ?? 0.0;
      final l = (log['lunch'] as num?)?.toDouble() ?? 0.0;
      final d = (log['dinner'] as num?)?.toDouble() ?? 0.0;

      rawMeals[uid] = (rawMeals[uid] ?? 0.0) + (b + l + d);
      weightedMeals[uid] =
          (weightedMeals[uid] ?? 0.0) + (b * bw + l * lw + d * dw);
    }

    final totalWeightedMeals =
        weightedMeals.values.fold(0.0, (sum, val) => sum + val);
    final totalRawMeals = rawMeals.values.fold(0.0, (sum, val) => sum + val);

    // Aggregate costs
    double totalFoodCost = 0.0;
    double totalFixedCost = 0.0;
    double totalOtherCost = 0.0;
    final Map<String, double> paidByUser = {};

    for (final raw in (costsData as List<dynamic>)) {
      final cost = raw as Map<String, dynamic>;
      final amount = (cost['amount'] as num?)?.toDouble() ?? 0.0;
      final paidBy = cost['paid_by'] as String;
      final costType = cost['cost_type'] as String? ?? 'variable';
      final category = cost['cost_categories'] as Map<String, dynamic>?;
      final isFood = category?['is_food'] as bool? ?? false;

      if (costType == 'variable' && isFood) {
        totalFoodCost += amount;
      } else if (costType == 'fixed') {
        totalFixedCost += amount;
      } else {
        totalOtherCost += amount;
      }

      paidByUser[paidBy] = (paidByUser[paidBy] ?? 0.0) + amount;
    }

    final mealRate =
        totalWeightedMeals > 0 ? totalFoodCost / totalWeightedMeals : 0.0;
    final memberCount = members.isEmpty ? 1 : members.length;
    final fixedPerMember = totalFixedCost / memberCount;
    final otherPerMember = totalOtherCost / memberCount;

    final summaries = members.map((m) {
      final userWeighted = weightedMeals[m.userId] ?? 0.0;
      final userRaw = rawMeals[m.userId] ?? 0.0;
      final foodCharge = userWeighted * mealRate;
      final totalPaid = paidByUser[m.userId] ?? 0.0;
      final totalOwed = foodCharge + fixedPerMember + otherPerMember;
      final netBalance = totalOwed - totalPaid;

      return MemberSettlementSummary(
        userId: m.userId,
        username: m.username ?? '',
        fullName: m.fullName ?? '',
        totalMeals: userRaw,
        weightedMeals: userWeighted,
        foodCharge: foodCharge,
        fixedShare: fixedPerMember,
        otherShare: otherPerMember,
        totalPaid: totalPaid,
        totalOwed: totalOwed,
        carryForwardIn: 0.0,
        netBalance: netBalance,
      );
    }).toList();

    final settlement = Settlement(
      houseId: houseId,
      cycleId: cycleId,
      totalFoodCost: totalFoodCost,
      totalFixedCost: totalFixedCost,
      totalOtherCost: totalOtherCost,
      totalMealCount: totalRawMeals,
      mealRate: mealRate,
      memberSummaries: summaries,
      computedAt: DateTime.now(),
      calculationEndDate: DateTime.tryParse(effectiveEndDate),
    );

    if (save) {
      await _supabase.from('settlements').upsert({
        'house_id': houseId,
        'cycle_id': cycleId,
        'total_food_cost': totalFoodCost,
        'total_fixed_cost': totalFixedCost,
        'total_other_cost': totalOtherCost,
        'total_meal_count': totalRawMeals,
        'meal_rate': mealRate,
        'computed_at': DateTime.now().toIso8601String(),
        'member_summaries': summaries
            .map((s) => {
                  'user_id': s.userId,
                  'username': s.username,
                  'full_name': s.fullName,
                  'total_meals': s.totalMeals,
                  'weighted_meals': s.weightedMeals,
                  'food_charge': s.foodCharge,
                  'fixed_share': s.fixedShare,
                  'other_share': s.otherShare,
                  'total_paid': s.totalPaid,
                  'total_owed': s.totalOwed,
                  'net_balance': s.netBalance,
                })
            .toList(),
      }, onConflict: 'cycle_id');
    }

    return settlement;
  }
}
