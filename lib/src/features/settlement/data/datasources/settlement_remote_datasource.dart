import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/features/cost/data/models/cost_model.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/settlement/data/models/settlement_model.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement_draft.dart';

class SettlementRemoteDatasource {
  const SettlementRemoteDatasource({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  static const _costSelectQuery = '''
    id,
    expense_account_id,
    cycle_id,
    paid_by,
    category_id,
    name,
    amount,
    cost_type,
    cost_scope,
    note,
    purchase_date,
    created_at,
    profiles (
      username,
      full_name
    ),
    cost_categories (
      name,
      icon
    )
  ''';

  String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String get _currentUserId =>
      _supabase.auth.currentUser?.id ?? '';

  /// Checks if an expense account ID belongs to a personal account.
  Future<bool> _isPersonalAccount(String houseId) async {
    try {
      final res = await _supabase
          .from('expense_accounts')
          .select('account_type')
          .eq('id', houseId)
          .maybeSingle();
      return res != null && res['account_type'] == 'personal';
    } catch (_) {
      return false;
    }
  }

  /// Fetches unsettled costs split into in-range and outstanding groups.
  Future<SettlementDraft> fetchSettlementDraft({
    required String houseId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final fromStr = _dateStr(fromDate);
    final toStr = _dateStr(toDate);
    final isPersonal = await _isPersonalAccount(houseId);

    // Get closed cycle IDs for this account to identify settled costs
    Set<String> closedCycleIds = {};
    try {
      final closedRes = await _supabase
          .from('billing_cycles')
          .select('id')
          .eq('expense_account_id', houseId)
          .eq('status', 'closed');
      closedCycleIds = (closedRes as List)
          .map((r) => r['id'] as String)
          .toSet();
    } catch (_) {}

    final List<dynamic> rows;
    if (isPersonal) {
      rows = await _supabase
          .from('costs')
          .select(_costSelectQuery)
          .eq('cost_scope', 'personal')
          .eq('paid_by', _currentUserId)
          .lte('purchase_date', toStr)
          .order('purchase_date', ascending: false)
          .order('created_at', ascending: false);
    } else {
      rows = await _supabase
          .from('costs')
          .select(_costSelectQuery)
          .eq('expense_account_id', houseId)
          .eq('cost_scope', 'shared')
          .lte('purchase_date', toStr)
          .order('purchase_date', ascending: false)
          .order('created_at', ascending: false);
    }

    final List<Cost> inRange = [];
    final List<Cost> outstanding = [];

    for (final r in rows) {
      final map = r as Map<String, dynamic>;
      final cId = map['cycle_id'] as String?;
      // If linked to a closed cycle, this cost was already settled
      if (cId != null && closedCycleIds.contains(cId)) {
        continue;
      }

      final cost = CostModel.fromJson(map);
      final pDate = map['purchase_date'] as String? ?? '';
      if (pDate.compareTo(fromStr) >= 0) {
        inRange.add(cost);
      } else {
        outstanding.add(cost);
      }
    }

    return SettlementDraft(
      houseId: houseId,
      fromDate: fromDate,
      toDate: toDate,
      inRangeCosts: inRange,
      outstandingCosts: outstanding,
    );
  }

  /// Computes and optionally saves a personal settlement (no meal count).
  Future<Settlement> _computePersonalSettlement({
    required String houseId,
    required DateTime fromDate,
    required DateTime toDate,
    required List<String> costIds,
    bool save = false,
    String? label,
  }) async {
    final costRows = await _supabase
        .from('costs')
        .select('*, cost_categories(id, name, is_food)')
        .inFilter('id', costIds);

    double totalFoodCost = 0;
    double totalFixedCost = 0;
    double totalOtherCost = 0;

    for (final r in (costRows as List)) {
      final amount = (r['amount'] as num?)?.toDouble() ?? 0.0;
      final costType = r['cost_type'] as String? ?? 'variable';
      final isFood =
          (r['cost_categories'] as Map<String, dynamic>?)?['is_food'] as bool? ??
              false;

      if (costType == 'variable' && isFood) {
        totalFoodCost += amount;
      } else if (costType == 'fixed') {
        totalFixedCost += amount;
      } else {
        totalOtherCost += amount;
      }
    }

    final totalExpenses = totalFoodCost + totalFixedCost + totalOtherCost;

    String username = '';
    String fullName = 'You';
    String? avatarUrl;
    try {
      final prof = await _supabase
          .from('profiles')
          .select('username, full_name, avatar_url')
          .eq('id', _currentUserId)
          .maybeSingle();
      if (prof != null) {
        username = prof['username'] as String? ?? '';
        fullName = prof['full_name'] as String? ??
            (username.isNotEmpty ? username : 'You');
        avatarUrl = prof['avatar_url'] as String?;
      }
    } catch (_) {}

    final memberSummary = MemberSettlementSummary(
      userId: _currentUserId,
      username: username,
      fullName: fullName,
      avatarUrl: avatarUrl,
      totalMeals: 0,
      weightedMeals: 0,
      foodCharge: totalFoodCost,
      fixedShare: totalFixedCost,
      otherShare: totalOtherCost,
      totalPaid: totalExpenses,
      totalOwed: totalExpenses,
      carryForwardIn: 0,
      netBalance: 0,
    );

    if (save) {
      final settlementLabel =
          label ?? '${_dateStr(fromDate)} – ${_dateStr(toDate)}';

      String? cycleId;

      // 1. Try to find an existing open cycle for this account to close it
      try {
        final openRows = await _supabase
            .from('billing_cycles')
            .select('id')
            .eq('expense_account_id', houseId)
            .eq('status', 'open')
            .order('start_date', ascending: false)
            .limit(1);

        if (openRows.isNotEmpty) {
          final openId = openRows.first['id'] as String;
          await _supabase.from('billing_cycles').update({
            'status': 'closed',
            'end_date': _dateStr(toDate),
            'closed_at': DateTime.now().toIso8601String(),
          }).eq('id', openId);
          cycleId = openId;
        }
      } catch (_) {}

      // 2. If no open cycle was found or closed, create a closed cycle for this settlement period
      if (cycleId == null) {
        try {
          final cycleRow = await _supabase
              .from('billing_cycles')
              .insert({
                'expense_account_id': houseId,
                'label': settlementLabel,
                'start_date': _dateStr(fromDate),
                'end_date': _dateStr(toDate),
                'status': 'closed',
                'created_by': _currentUserId,
                'closed_at': DateTime.now().toIso8601String(),
              })
              .select('id')
              .single();
          cycleId = cycleRow['id'] as String?;
        } catch (_) {
          try {
            final cycleRow = await _supabase
                .from('billing_cycles')
                .insert({
                  'expense_account_id': houseId,
                  'label': settlementLabel,
                  'start_date': _dateStr(fromDate),
                  'end_date': _dateStr(toDate),
                  'status': 'closed',
                  'cycle_type': 'dynamic',
                  'created_by': _currentUserId,
                  'closed_at': DateTime.now().toIso8601String(),
                })
                .select('id')
                .single();
            cycleId = cycleRow['id'] as String?;
          } catch (_) {
            // Fallback: create as open first then update to closed (satisfies insert RLS)
            final cycleRow = await _supabase
                .from('billing_cycles')
                .insert({
                  'expense_account_id': houseId,
                  'label': settlementLabel,
                  'start_date': _dateStr(fromDate),
                  'status': 'open',
                  'created_by': _currentUserId,
                })
                .select('id')
                .single();
            final newId = cycleRow['id'] as String?;
            if (newId != null) {
              await _supabase.from('billing_cycles').update({
                'status': 'closed',
                'end_date': _dateStr(toDate),
                'closed_at': DateTime.now().toIso8601String(),
              }).eq('id', newId);
              cycleId = newId;
            }
          }
        }
      }

      if (cycleId == null || cycleId.isEmpty) {
        throw Exception('Failed to obtain a valid billing cycle for settlement.');
      }

      Map<String, dynamic>? settlementRow;
      final settlementPayload = {
        'expense_account_id': houseId,
        'cycle_id': cycleId,
        'from_date': _dateStr(fromDate),
        'to_date': _dateStr(toDate),
        'status': 'finalised',
        'total_food_cost': totalFoodCost,
        'total_fixed_cost': totalFixedCost,
        'total_other_cost': totalOtherCost,
        'total_meal_count': 0,
        'meal_rate': 0,
        'member_summaries': [
          {
            'user_id': _currentUserId,
            'username': username,
            'full_name': fullName,
            'avatar_url': avatarUrl,
            'total_meals': 0,
            'weighted_meals': 0,
            'food_charge': totalFoodCost,
            'fixed_share': totalFixedCost,
            'other_share': totalOtherCost,
            'total_paid': totalExpenses,
            'carry_forward_in': 0,
            'total_owed': totalExpenses,
            'net_balance': 0,
          }
        ],
        'computed_by': _currentUserId,
        'computed_at': DateTime.now().toIso8601String(),
      };

      try {
        settlementRow = await _supabase
            .from('settlements')
            .insert(settlementPayload)
            .select('id')
            .single();
      } catch (_) {
        // Fallback without from_date, to_date, status in case columns are not present
        final minimalPayload = Map<String, dynamic>.from(settlementPayload)
          ..remove('from_date')
          ..remove('to_date')
          ..remove('status');
        settlementRow = await _supabase
            .from('settlements')
            .insert(minimalPayload)
            .select('id')
            .single();
      }

      final settlementId = (settlementRow['id'] as String?) ?? '';

      // Mark all included personal costs as settled
      if (costIds.isNotEmpty) {
        try {
          await _supabase
              .from('costs')
              .update({'cycle_id': cycleId})
              .inFilter('id', costIds);
        } catch (_) {}

        if (settlementId.isNotEmpty) {
          try {
            await _supabase
                .from('costs')
                .update({'settlement_id': settlementId})
                .inFilter('id', costIds);
          } catch (_) {}
        }
      }

      // Start the next continuous cycle for the personal account so future costs can be tracked
      try {
        final existingCount = await _supabase
            .from('billing_cycles')
            .select('id')
            .eq('expense_account_id', houseId);
        final nextNum = (existingCount as List).length + 1;
        final nextStart = toDate.add(const Duration(days: 1));
        await _supabase.from('billing_cycles').insert({
          'expense_account_id': houseId,
          'label': 'Cycle $nextNum',
          'start_date': _dateStr(nextStart),
          'status': 'open',
          'created_by': _currentUserId,
        });
      } catch (_) {}

      return Settlement(
        houseId: houseId,
        cycleId: cycleId,
        settlementId: settlementId,
        fromDate: fromDate,
        toDate: toDate,
        totalFoodCost: totalFoodCost,
        totalFixedCost: totalFixedCost,
        totalOtherCost: totalOtherCost,
        totalMealCount: 0,
        mealRate: 0,
        memberSummaries: [memberSummary],
        status: SettlementStatus.finalised,
        computedAt: DateTime.now(),
        includedCostIds: costIds,
      );
    }

    return Settlement(
      houseId: houseId,
      fromDate: fromDate,
      toDate: toDate,
      totalFoodCost: totalFoodCost,
      totalFixedCost: totalFixedCost,
      totalOtherCost: totalOtherCost,
      totalMealCount: 0,
      mealRate: 0,
      memberSummaries: [memberSummary],
      status: SettlementStatus.draft,
      includedCostIds: costIds,
    );
  }

  /// Calls the edge function to compute and optionally save a settlement.
  Future<Settlement> computeSettlement({
    required String houseId,
    required DateTime fromDate,
    required DateTime toDate,
    required List<String> costIds,
    bool save = false,
    String? status,
    String? label,
  }) async {
    final isPersonal = await _isPersonalAccount(houseId);
    if (isPersonal) {
      return _computePersonalSettlement(
        houseId: houseId,
        fromDate: fromDate,
        toDate: toDate,
        costIds: costIds,
        save: save,
        label: label,
      );
    }

    final res = await _supabase.functions.invoke(
      'compute-settlement',
      body: {
        'expense_account_id': houseId,
        'from_date': _dateStr(fromDate),
        'to_date': _dateStr(toDate),
        'cost_ids': costIds,
        'save': save,
        if (status != null) 'status': status,
        if (label != null) 'label': label,
      },
    );

    if (res.status != 200 || res.data == null) {
      final errorMsg = res.data is Map && res.data['error'] != null
          ? res.data['error'].toString()
          : 'Failed to compute settlement (status: ${res.status})';
      throw Exception(errorMsg);
    }

    final payload = res.data is Map && res.data['data'] != null
        ? res.data['data'] as Map<String, dynamic>
        : res.data as Map<String, dynamic>;

    return SettlementModel.fromJson(payload);
  }

  /// Records a settlement payment from a member towards their calculated due.
  Future<Settlement> recordSettlementPayment({
    required String settlementId,
    required String userId,
    required double amount,
    String? note,
  }) async {
    final row = await _supabase
        .from('settlements')
        .select('*')
        .eq('id', settlementId)
        .single();

    final settlement = SettlementModel.fromJson(row);

    // Record deposit entry
    await _supabase.from('deposits').insert({
      'expense_account_id': settlement.houseId,
      'user_id': userId,
      'settlement_id': settlementId,
      'deposit_type': 'settlement_due',
      'amount': amount,
      'note': note?.trim().isEmpty == true ? null : note?.trim(),
      'deposit_date': DateTime.now().toIso8601String().split('T').first,
      'recorded_by': _currentUserId,
    });

    // Update member summaries with collected deposit
    final updatedSummaries = settlement.memberSummaries.map((m) {
      if (m.userId == userId) {
        final newSettlementDeposits = m.settlementDeposits + amount;
        final newFinalBalance = m.payable - newSettlementDeposits;
        return MemberSettlementSummaryModel(
          userId: m.userId,
          username: m.username,
          fullName: m.fullName,
          avatarUrl: m.avatarUrl,
          totalMeals: m.totalMeals,
          weightedMeals: m.weightedMeals,
          foodCharge: m.foodCharge,
          fixedShare: m.fixedShare,
          otherShare: m.otherShare,
          totalPaid: m.totalPaid,
          totalOwed: m.totalOwed,
          carryForwardIn: m.carryForwardIn,
          netBalance: m.netBalance,
          advanceDeposits: m.advanceDeposits,
          settlementDeposits: newSettlementDeposits,
          finalBalance: newFinalBalance,
          resolutionType: m.resolutionType,
          resolutionReason: m.resolutionReason,
          carryForwardReference: m.carryForwardReference,
        );
      }
      return MemberSettlementSummaryModel(
        userId: m.userId,
        username: m.username,
        fullName: m.fullName,
        avatarUrl: m.avatarUrl,
        totalMeals: m.totalMeals,
        weightedMeals: m.weightedMeals,
        foodCharge: m.foodCharge,
        fixedShare: m.fixedShare,
        otherShare: m.otherShare,
        totalPaid: m.totalPaid,
        totalOwed: m.totalOwed,
        carryForwardIn: m.carryForwardIn,
        netBalance: m.netBalance,
        advanceDeposits: m.advanceDeposits,
        settlementDeposits: m.settlementDeposits,
        finalBalance: m.finalBalance,
        resolutionType: m.resolutionType,
        resolutionReason: m.resolutionReason,
        carryForwardReference: m.carryForwardReference,
      );
    }).toList();

    final updatedRow = await _supabase
        .from('settlements')
        .update({
          'member_summaries': updatedSummaries.map((s) => s.toJson()).toList(),
        })
        .eq('id', settlementId)
        .select()
        .single();

    return SettlementModel.fromJson(updatedRow);
  }

  /// Finalises a published settlement with member balance resolutions.
  Future<Settlement> finaliseSettlementWithResolutions({
    required String settlementId,
    required List<MemberResolutionParams> resolutions,
  }) async {
    final row = await _supabase
        .from('settlements')
        .select('*')
        .eq('id', settlementId)
        .single();

    final settlement = SettlementModel.fromJson(row);
    final resMap = {for (final r in resolutions) r.userId: r};

    final updatedSummaries = settlement.memberSummaries.map((m) {
      final res = resMap[m.userId];
      final finalBal = m.payable - m.settlementDeposits;
      return MemberSettlementSummaryModel(
        userId: m.userId,
        username: m.username,
        fullName: m.fullName,
        avatarUrl: m.avatarUrl,
        totalMeals: m.totalMeals,
        weightedMeals: m.weightedMeals,
        foodCharge: m.foodCharge,
        fixedShare: m.fixedShare,
        otherShare: m.otherShare,
        totalPaid: m.totalPaid,
        totalOwed: m.totalOwed,
        carryForwardIn: m.carryForwardIn,
        netBalance: m.netBalance,
        advanceDeposits: m.advanceDeposits,
        settlementDeposits: m.settlementDeposits,
        finalBalance: finalBal,
        resolutionType: res?.resolutionType ?? BalanceResolutionType.carryForward,
        resolutionReason: res?.resolutionReason,
        carryForwardReference: m.carryForwardReference,
      );
    }).toList();

    final updatedRow = await _supabase
        .from('settlements')
        .update({
          'status': 'finalised',
          'member_summaries': updatedSummaries.map((s) => s.toJson()).toList(),
        })
        .eq('id', settlementId)
        .select()
        .single();

    return SettlementModel.fromJson(updatedRow);
  }

  /// Fetches an ongoing published settlement for an account, if any.
  Future<Settlement?> getPublishedSettlement({required String houseId}) async {
    try {
      final rows = await _supabase
          .from('settlements')
          .select('*, billing_cycles(start_date, end_date, label)')
          .eq('expense_account_id', houseId)
          .eq('status', 'published')
          .order('computed_at', ascending: false)
          .limit(1);

      if ((rows as List).isEmpty) return null;
      final map = Map<String, dynamic>.from(rows.first);
      return SettlementModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Lists all finalised settlements for an account, newest first.
  Future<List<Settlement>> getSettlements({required String houseId}) async {
    try {
      final rows = await _supabase
          .from('settlements')
          .select('*, billing_cycles(start_date, end_date, label)')
          .eq('expense_account_id', houseId)
          .order('computed_at', ascending: false);

      return (rows as List).map((r) {
        final map = Map<String, dynamic>.from(r as Map<String, dynamic>);
        final cycle = map['billing_cycles'] as Map<String, dynamic>?;
        if (map['from_date'] == null && cycle?['start_date'] != null) {
          map['from_date'] = cycle!['start_date'];
        }
        if (map['to_date'] == null && cycle?['end_date'] != null) {
          map['to_date'] = cycle!['end_date'];
        }
        return SettlementModel.fromJson(map);
      }).toList();
    } catch (_) {
      try {
        final rows = await _supabase
            .from('settlements')
            .select('*')
            .eq('expense_account_id', houseId)
            .order('computed_at', ascending: false);

        return (rows as List)
            .map((r) => SettlementModel.fromJson(r as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }
}
