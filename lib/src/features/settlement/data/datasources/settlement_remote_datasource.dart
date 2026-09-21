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
    house_id,
    cycle_id,
    settlement_id,
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

  /// Fetches unsettled costs split into in-range and outstanding groups.
  Future<SettlementDraft> fetchSettlementDraft({
    required String houseId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final fromStr = _dateStr(fromDate);
    final toStr = _dateStr(toDate);

    // In-range costs: purchase_date in [from, to], not yet settled, shared
    final inRangeRows = await _supabase
        .from('costs')
        .select(_costSelectQuery)
        .eq('house_id', houseId)
        .eq('cost_scope', 'shared')
        .isFilter('settlement_id', null)
        .gte('purchase_date', fromStr)
        .lte('purchase_date', toStr)
        .order('purchase_date', ascending: false)
        .order('created_at', ascending: false);

    // Outstanding: purchase_date < from, not yet settled, shared
    final outstandingRows = await _supabase
        .from('costs')
        .select(_costSelectQuery)
        .eq('house_id', houseId)
        .eq('cost_scope', 'shared')
        .isFilter('settlement_id', null)
        .lt('purchase_date', fromStr)
        .order('purchase_date', ascending: false)
        .order('created_at', ascending: false);

    final inRange = (inRangeRows as List)
        .map((r) => CostModel.fromJson(r as Map<String, dynamic>) as Cost)
        .toList();

    final outstanding = (outstandingRows as List)
        .map((r) => CostModel.fromJson(r as Map<String, dynamic>) as Cost)
        .toList();

    return SettlementDraft(
      houseId: houseId,
      fromDate: fromDate,
      toDate: toDate,
      inRangeCosts: inRange,
      outstandingCosts: outstanding,
    );
  }

  /// Calls the edge function to compute and optionally save a settlement.
  Future<Settlement> computeSettlement({
    required String houseId,
    required DateTime fromDate,
    required DateTime toDate,
    required List<String> costIds,
    bool save = false,
    String? label,
  }) async {
    final res = await _supabase.functions.invoke(
      'compute-settlement',
      body: {
        'house_id': houseId,
        'from_date': _dateStr(fromDate),
        'to_date': _dateStr(toDate),
        'cost_ids': costIds,
        'save': save,
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

  /// Lists all finalised settlements for an account, newest first.
  Future<List<Settlement>> getSettlements({required String houseId}) async {
    try {
      final rows = await _supabase
          .from('settlements')
          .select('*')
          .eq('house_id', houseId)
          .eq('status', 'finalised')
          .order('to_date', ascending: false)
          .order('computed_at', ascending: false);

      return (rows as List)
          .map((r) => SettlementModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
