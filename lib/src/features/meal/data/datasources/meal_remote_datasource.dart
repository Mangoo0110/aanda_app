import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/features/meal/data/models/meal_log_model.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';

class MealRemoteDatasource {
  const MealRemoteDatasource({required SupabaseClient supabase})
      : _supabase = supabase;

  final SupabaseClient _supabase;

  Future<List<MealLog>> getMealLogs({
    required String houseId,
    required String cycleId,
    DateTime? date,
  }) async {
    var query = _supabase
        .from('meal_logs')
        .select('*, profiles(id, full_name, username)')
        .eq('house_id', houseId)
        .eq('cycle_id', cycleId);

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
    final data = await _supabase
        .from('meal_logs')
        .upsert(
          {
            'house_id': houseId,
            'cycle_id': cycleId,
            'user_id': userId,
            'log_date': dateStr,
            'breakfast': breakfast,
            'lunch': lunch,
            'dinner': dinner,
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'house_id,user_id,log_date',
        )
        .select('*, profiles(id, full_name, username)')
        .single();

    return MealLogModel.fromJson(data);
  }
}
