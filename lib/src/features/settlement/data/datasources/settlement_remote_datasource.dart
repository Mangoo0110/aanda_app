import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/features/settlement/data/models/settlement_model.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';

class SettlementRemoteDatasource {
  const SettlementRemoteDatasource({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  /// Calls the backend edge function `compute-settlement` to compute settlement
  /// for [cycleId] up to [calculationDate] (defaulting to the exact tap date / today).
  ///
  /// All computations (meal weighting, shared cost splits, and balances)
  /// are executed on the backend.
  Future<Settlement> computeSettlement({
    required String cycleId,
    DateTime? calculationDate,
    bool save = false,
  }) async {
    final effectiveCutoff = calculationDate ?? DateTime.now();
    final cutoffIso = effectiveCutoff.toIso8601String().substring(0, 10);

    final res = await _supabase.functions.invoke(
      'compute-settlement',
      body: {'cycle_id': cycleId, 'calculation_date': cutoffIso, 'save': save},
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

  /// Attempts to fetch an already-persisted settlement from the `cycle_settlements` table.
  /// Returns null if not yet persisted or table doesn't exist yet.
  Future<Settlement?> getPersistedSettlement({required String cycleId}) async {
    try {
      final res = await _supabase
          .from('cycle_settlements')
          .select('*')
          .eq('cycle_id', cycleId)
          .maybeSingle();

      if (res != null) {
        return SettlementModel.fromJson(res);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
