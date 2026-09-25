import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/features/settlement/domain/entities/deposit.dart';

class DepositRemoteDatasource {
  const DepositRemoteDatasource({required SupabaseClient supabase})
      : _supabase = supabase;

  final SupabaseClient _supabase;

  String get _currentUserId => _supabase.auth.currentUser!.id;

  /// Records a cash / bank / digital deposit for a member.
  Future<Deposit> recordDeposit({
    required String houseId,
    required String userId,
    required double amount,
    required DepositType depositType,
    String? settlementId,
    String? costId,
    String? note,
    DateTime? depositDate,
  }) async {
    final dateStr = (depositDate ?? DateTime.now()).toIso8601String().split('T').first;

    final row = await _supabase.from('deposits').insert({
      'expense_account_id': houseId,
      'user_id': userId,
      'settlement_id': settlementId,
      'cost_id': costId,
      'deposit_type': depositType.value,
      'amount': amount,
      'note': note?.trim().isEmpty == true ? null : note?.trim(),
      'deposit_date': dateStr,
      'recorded_by': _currentUserId,
    }).select('*, profiles:user_id(id, full_name, username, avatar_url)').single();

    return Deposit.fromJson(row);
  }

  /// Fetches all deposits made for a specific settlement during collection.
  Future<List<Deposit>> getDepositsForSettlement(String settlementId) async {
    try {
      final rows = await _supabase
          .from('deposits')
          .select('*, profiles:user_id(id, full_name, username, avatar_url)')
          .eq('settlement_id', settlementId)
          .order('created_at', ascending: false);

      return (rows as List).map((r) => Deposit.fromJson(r as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches all deposits in a house within an optional date range.
  Future<List<Deposit>> getDepositsForHouse({
    required String houseId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _supabase
          .from('deposits')
          .select('*, profiles:user_id(id, full_name, username, avatar_url)')
          .eq('expense_account_id', houseId);

      if (fromDate != null) {
        final fStr = fromDate.toIso8601String().split('T').first;
        query = query.gte('deposit_date', fStr);
      }
      if (toDate != null) {
        final tStr = toDate.toIso8601String().split('T').first;
        query = query.lte('deposit_date', tStr);
      }

      final rows = await query.order('deposit_date', ascending: false);
      return (rows as List).map((r) => Deposit.fromJson(r as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Updates an existing deposit entry.
  Future<Deposit> updateDeposit({
    required String depositId,
    required String userId,
    required double amount,
    required DepositType depositType,
    String? note,
    DateTime? depositDate,
  }) async {
    final dateStr = (depositDate ?? DateTime.now()).toIso8601String().split('T').first;

    final row = await _supabase
        .from('deposits')
        .update({
          'user_id': userId,
          'deposit_type': depositType.value,
          'amount': amount,
          'note': note?.trim().isEmpty == true ? null : note?.trim(),
          'deposit_date': dateStr,
        })
        .eq('id', depositId)
        .select('*, profiles:user_id(id, full_name, username, avatar_url)')
        .single();

    return Deposit.fromJson(row);
  }

  /// Deletes a recorded deposit entry.
  Future<void> deleteDeposit(String depositId) async {
    await _supabase.from('deposits').delete().eq('id', depositId);
  }
}
