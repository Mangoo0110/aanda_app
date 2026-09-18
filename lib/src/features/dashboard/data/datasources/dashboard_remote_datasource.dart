import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/features/dashboard/data/models/dashboard_activity_model.dart';
import 'package:aanda/src/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:aanda/src/features/dashboard/domain/entities/dashboard_activity.dart';

class DashboardRemoteDatasource {
  DashboardRemoteDatasource({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  String get _currentUserId =>
      _supabase.auth.currentUser?.id ?? (throw Exception('Not authenticated'));

  Future<DashboardSummaryModel> getDashboardSummary({
    String? houseId,
    String? month,
  }) async {
    final now = DateTime.now();
    final targetMonth =
        month ?? '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // 1. Try custom Supabase Edge Function first
    try {
      final res = await _supabase.functions.invoke(
        'dashboard',
        body: {
          'action': 'summary',
          'month': targetMonth,
          if (houseId != null) 'house_id': houseId,
        },
      );

      if (res.status == 200 && res.data != null) {
        final body = res.data;
        if (body is Map && body['success'] == true && body['data'] != null) {
          return DashboardSummaryModel.fromJson(
            body['data'] as Map<String, dynamic>,
          );
        }
      }
    } catch (_) {
      // Edge function failed or is not yet deployed; proceed to fallback query
    }

    // 2. Direct Supabase query fallback
    return _queryDirectFallback(houseId: houseId, targetMonth: targetMonth);
  }

  Future<DashboardSummaryModel> _queryDirectFallback({
    String? houseId,
    required String targetMonth,
  }) async {
    final parts = targetMonth.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;

    final startDate =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final endDate =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    // 1. Personal costs for current user
    final personalRows = await _supabase
        .from('costs')
        .select('id, name, amount, purchase_date, created_at')
        .eq('paid_by', _currentUserId)
        .eq('cost_scope', 'personal')
        .gte('purchase_date', startDate)
        .lte('purchase_date', endDate);

    double personalSpent = 0;
    final List<DashboardActivityModel> activities = [];

    for (final r in personalRows) {
      final amt = (r['amount'] as num?)?.toDouble() ?? 0.0;
      personalSpent += amt;

      final pDate =
          DateTime.tryParse(r['purchase_date'] as String? ?? '') ??
          DateTime.now();
      activities.add(
        DashboardActivityModel(
          id: 'cost-${r['id']}',
          type: DashboardActivityType.expense,
          title:
              'Expense: BDT ${amt.toStringAsFixed(0)} ${(r['name'] as String).toLowerCase()} by You (Personal)',
          tag: 'Personal',
          timestamp: pDate,
          amount: amt,
        ),
      );
    }

    // 2. Houses the user belongs to
    final memberships = await _supabase
        .from('house_members')
        .select('house_id')
        .eq('user_id', _currentUserId);

    final houseIds = (memberships as List)
        .map((m) => m['house_id'] as String)
        .toList();

    double totalHouseSpent = 0;
    double myHouseContribution = 0;

    final targetHouseIds = houseId != null ? [houseId] : houseIds;

    if (targetHouseIds.isNotEmpty) {
      final sharedRows = await _supabase
          .from('costs')
          .select(
            'id, house_id, paid_by, name, amount, purchase_date, created_at, profiles(username, full_name)',
          )
          .inFilter('house_id', targetHouseIds)
          .eq('cost_scope', 'shared')
          .gte('purchase_date', startDate)
          .lte('purchase_date', endDate);

      for (final r in sharedRows) {
        final amt = (r['amount'] as num?)?.toDouble() ?? 0.0;
        totalHouseSpent += amt;
        final payerId = r['paid_by'] as String?;
        if (payerId == _currentUserId) {
          myHouseContribution += amt;
        }

        final profile = r['profiles'] as Map<String, dynamic>?;
        final payerName = payerId == _currentUserId
            ? 'You'
            : (profile?['full_name'] ?? profile?['username'] ?? 'Member');

        final pDate =
            DateTime.tryParse(r['purchase_date'] as String? ?? '') ??
            DateTime.now();

        activities.add(
          DashboardActivityModel(
            id: 'cost-${r['id']}',
            type: DashboardActivityType.expense,
            title:
                'Expense: BDT ${amt.toStringAsFixed(0)} ${(r['name'] as String).toLowerCase()} by $payerName',
            tag: 'Shared House',
            timestamp: pDate,
            amount: amt,
          ),
        );
      }

      // 3. Meals from meal_logs
      try {
        final mealRows = await _supabase
            .from('meal_logs')
            .select(
              'id, user_id, log_date, breakfast, lunch, dinner, created_at, updated_at, profiles(username, full_name)',
            )
            .inFilter('house_id', targetHouseIds)
            .order('updated_at', ascending: false)
            .limit(5);

        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

        for (final m in mealRows) {
          final profile = m['profiles'] as Map<String, dynamic>?;
          final memberName = m['user_id'] == _currentUserId
              ? 'You'
              : (profile?['full_name'] ?? profile?['username'] ?? 'Member');

          final logDate = m['log_date'] as String? ?? '';
          final dateStr = logDate == todayStr ? 'today' : logDate;

          final breakfast = (m['breakfast'] as num?)?.toDouble() ?? 0;
          final lunch = (m['lunch'] as num?)?.toDouble() ?? 0;
          final dinner = (m['dinner'] as num?)?.toDouble() ?? 0;

          final parts = <String>[];
          if (dinner > 0) parts.add('${dinner == 1 ? "1" : dinner} dinner');
          if (lunch > 0) parts.add('${lunch == 1 ? "1" : lunch} lunch');
          if (breakfast > 0)
            parts.add('${breakfast == 1 ? "1" : breakfast} breakfast');

          final mealDesc = parts.isNotEmpty ? parts.join(', ') : 'meal';
          final mDate =
              DateTime.tryParse(m['updated_at'] as String? ?? '') ??
              DateTime.now();

          activities.add(
            DashboardActivityModel(
              id: 'meal-${m['id']}',
              type: DashboardActivityType.meal,
              title:
                  'Meal: $mealDesc added/updated for $dateStr for $memberName',
              tag: 'House Meal',
              timestamp: mDate,
            ),
          );
        }
      } catch (_) {}
    }

    // Sort descending by timestamp
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return DashboardSummaryModel(
      month: targetMonth,
      personalSpent: personalSpent,
      totalHouseSpent: totalHouseSpent,
      myHouseContribution: myHouseContribution,
      activities: activities.take(15).toList(),
    );
  }
}
