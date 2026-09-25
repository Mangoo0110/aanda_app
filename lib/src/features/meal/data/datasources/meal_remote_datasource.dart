import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/features/meal/data/models/meal_log_model.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';

class MealRemoteDatasource {
  const MealRemoteDatasource({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  Future<String?> _resolveCycleId(String houseId, String cycleId) async {
    if (cycleId.isNotEmpty) return cycleId;
    try {
      final rows = await _supabase
          .from('billing_cycles')
          .select('id')
          .eq('expense_account_id', houseId)
          .eq('status', 'open')
          .order('start_date', ascending: false)
          .limit(1);
      if (rows.isNotEmpty) {
        return rows.first['id'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<List<MealLog>> getMealLogs({
    required String houseId,
    required String cycleId,
    DateTime? date,
  }) async {
    var query = _supabase
        .from('meal_logs')
        .select('*, profiles(id, full_name, username)')
        .eq('expense_account_id', houseId);

    final resolvedCycle = await _resolveCycleId(houseId, cycleId);
    if (resolvedCycle != null && resolvedCycle.isNotEmpty) {
      query = query.eq('cycle_id', resolvedCycle);
    }

    if (date != null) {
      final dateStr = date.toIso8601String().substring(0, 10);
      query = query.eq('log_date', dateStr);
    }

    final data = await query.order('log_date', ascending: false);
    return (data as List<dynamic>)
        .map((e) => MealLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MealLog> upsertMealLog({
    required String houseId,
    required String cycleId,
    required String userId,
    required DateTime logDate,
    required double breakfast,
    required double lunch,
    required double dinner,
  }) async {
    final dateStr = logDate.toIso8601String().substring(0, 10);
    final resolvedCycle = await _resolveCycleId(houseId, cycleId);

    final payload = <String, dynamic>{
      'expense_account_id': houseId,
      'user_id': userId,
      'log_date': dateStr,
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (resolvedCycle != null && resolvedCycle.isNotEmpty) {
      payload['cycle_id'] = resolvedCycle;
    }

    final data = await _supabase
        .from('meal_logs')
        .upsert(payload, onConflict: 'expense_account_id,user_id,log_date')
        .select('*, profiles(id, full_name, username)')
        .single();

    return MealLogModel.fromJson(data);
  }
}
