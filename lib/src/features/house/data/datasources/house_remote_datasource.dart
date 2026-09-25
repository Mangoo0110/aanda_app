import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/features/house/data/models/house_invite_model.dart';
import 'package:aanda/src/features/house/data/models/house_member_model.dart';
import 'package:aanda/src/features/house/data/models/house_model.dart';
import 'package:aanda/src/features/house/data/models/sprint_model.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/entities/house_invite.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';

/// Supabase-backed datasource for the `houses` and `house_members` tables.
class HouseRemoteDatasource {
  HouseRemoteDatasource({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  String get _currentUserId =>
      _supabase.auth.currentUser?.id ?? (throw Exception('Not authenticated'));

  // ── Houses ─────────────────────────────────────────────────────────────────

  Future<House> createHouse({required String name, String? avatarUrl}) async {
    final insertData = <String, dynamic>{
      'name': name,
      'created_by': _currentUserId,
      'account_type': 'shared',
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };

    final data = await _supabase
        .from('expense_accounts')
        .insert(insertData)
        .select()
        .single();

    final house = HouseModel.fromJson(data);

    // Insert the creator as admin member.
    await _supabase.from('expense_account_members').insert({
      'expense_account_id': house.id,
      'user_id': _currentUserId,
      'role': 'admin',
    });

    return house;
  }

  Future<House> joinHouse({required String inviteCode}) async {
    // Find the house by invite code.
    final houseData = await _supabase
        .from('expense_accounts')
        .select()
        .eq('invite_code', inviteCode.trim().toUpperCase())
        .maybeSingle();

    if (houseData == null) {
      throw Exception('House not found. Check the invite code and try again.');
    }

    final house = HouseModel.fromJson(houseData);

    // Check not already a member.
    final existing = await _supabase
        .from('expense_account_members')
        .select('id')
        .eq('expense_account_id', house.id)
        .eq('user_id', _currentUserId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('You are already a member of this house.');
    }

    await _supabase.from('expense_account_members').insert({
      'expense_account_id': house.id,
      'user_id': _currentUserId,
      'role': 'member',
    });

    return house;
  }

  Future<List<House>> getMyHouses() async {
    final rows = await _supabase
        .from('expense_account_members')
        .select('expense_account_id, expense_accounts(*)')
        .eq('user_id', _currentUserId);

    return rows
        .map((r) => HouseModel.fromJson(r['expense_accounts'] as Map<String, dynamic>))
        .toList();
  }

  Future<House> getHouseDetail({required String houseId}) async {
    final houseData = await _supabase
        .from('expense_accounts')
        .select()
        .eq('id', houseId)
        .single();

    final members = await getHouseMembers(houseId: houseId);
    return HouseModel.fromJsonWithMembers(houseData, members);
  }

  Future<String> uploadHouseAvatar({
    required String houseId,
    required List<int> fileBytes,
    required String fileExtension,
  }) async {
    final ext = fileExtension.replaceAll('.', '').toLowerCase();
    final path = 'houses/$houseId/avatar.$ext';
    final mime = ext == 'png'
        ? 'image/png'
        : (ext == 'webp' ? 'image/webp' : 'image/jpeg');

    await _supabase.storage.from('avatars').uploadBinary(
      path,
      Uint8List.fromList(fileBytes),
      fileOptions: FileOptions(upsert: true, contentType: mime),
    );

    final rawUrl = _supabase.storage.from('avatars').getPublicUrl(path);
    return '$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> updateHouseAvatarUrl({
    required String houseId,
    required String avatarUrl,
  }) async {
    try {
      await _supabase
          .from('expense_accounts')
          .update({'avatar_url': avatarUrl})
          .eq('id', houseId);
    } catch (e) {
      debugPrint('updateHouseAvatarUrl warning: $e');
    }
  }

  // ── Invites ────────────────────────────────────────────────────────────────

  Future<HouseInvite> getHouseInvite({required String houseId}) async {
    final data = await _supabase
        .from('expense_accounts')
        .select('id, invite_code')
        .eq('id', houseId)
        .single();

    return HouseInviteModel.fromJson(data);
  }

  Future<HouseInvite> regenerateInviteCode({required String houseId}) async {
    final newCode = _generateCode();
    await _supabase
        .from('expense_accounts')
        .update({'invite_code': newCode})
        .eq('id', houseId);
    return HouseInviteModel(code: newCode, houseId: houseId);
  }

  // ── Members ────────────────────────────────────────────────────────────────

  Future<List<HouseMember>> getHouseMembers({required String houseId}) async {
    final rows = await _supabase
        .from('expense_account_members')
        .select('*, profiles(username, full_name, avatar_url)')
        .eq('expense_account_id', houseId)
        .order('joined_at');

    return rows.map((r) => HouseMemberModel.fromJson(r)).toList();
  }

  Future<void> leaveHouse({required String houseId}) async {
    await _supabase
        .from('expense_account_members')
        .delete()
        .eq('expense_account_id', houseId)
        .eq('user_id', _currentUserId);
  }

  Future<void> removeMember({
    required String houseId,
    required String userId,
  }) async {
    await _supabase
        .from('expense_account_members')
        .delete()
        .eq('expense_account_id', houseId)
        .eq('user_id', userId);
  }

  // ── Sprints (Billing Cycles) ───────────────────────────────────────────────

  Future<List<Sprint>> getSprints({required String houseId}) async {
    final rows = await _supabase
        .from('billing_cycles')
        .select()
        .eq('expense_account_id', houseId)
        .order('start_date', ascending: false);

    if (rows.isEmpty) {
      try {
        final initial = await ensureRunningSprint(houseId: houseId);
        return [initial];
      } catch (_) {
        return [];
      }
    }

    return rows.map((r) => SprintModel.fromJson(r)).toList();
  }

  Future<Sprint> ensureRunningSprint({required String houseId}) async {
    final openRows = await _supabase
        .from('billing_cycles')
        .select()
        .eq('expense_account_id', houseId)
        .eq('status', 'open')
        .order('start_date', ascending: false)
        .limit(1);

    if (openRows.isNotEmpty) {
      return SprintModel.fromJson(openRows.first);
    }

    // Count existing cycles to generate label
    final allRows = await _supabase
        .from('billing_cycles')
        .select('id')
        .eq('expense_account_id', houseId);
    final count = allRows.length;

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);

    // Open cycles have no end_date — it is set only when the admin closes the cycle.
    return createSprint(
      houseId: houseId,
      label: 'Cycle ${count + 1}',
      startDate: startDate,
      endDate: null,
    );
  }

  Future<Sprint> createSprint({
    required String houseId,
    required String label,
    required DateTime startDate,
    DateTime? endDate, // null = open cycle; set when admin closes it
  }) async {
    final data = await _supabase
        .from('billing_cycles')
        .insert({
          'expense_account_id': houseId,
          'label': label,
          'start_date': startDate.toIso8601String().substring(0, 10),
          if (endDate != null)
            'end_date': endDate.toIso8601String().substring(0, 10),
          'status': 'open',
          'created_by': _currentUserId,
        })
        .select()
        .single();

    return SprintModel.fromJson(data);
  }

  Future<Sprint> closeSprint({
    required String cycleId,
    DateTime? closedAt,
  }) async {
    final effectiveClose = closedAt ?? DateTime.now();
    final data = await _supabase
        .from('billing_cycles')
        .update({
          'status': 'closed',
          'end_date': effectiveClose.toIso8601String().substring(0, 10),
          'closed_at': effectiveClose.toIso8601String(),
        })
        .eq('id', cycleId)
        .select()
        .single();

    return SprintModel.fromJson(data);
  }

  // ── Sprint Stats (Quick Summary for House Detail) ──────────────────────────

  Future<Map<String, dynamic>> getSprintStats({
    required String houseId,
    required String? cycleId,   // kept for API compatibility, now optional
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startStr = startDate.toIso8601String().substring(0, 10);
    final endStr = endDate.toIso8601String().substring(0, 10);

    // 1. Costs in date range
    final costs = await _supabase
        .from('costs')
        .select('amount, paid_by, cost_type, cost_categories(is_food)')
        .eq('expense_account_id', houseId)
        .eq('cost_scope', 'shared')
        .gte('purchase_date', startStr)
        .lte('purchase_date', endStr);

    double totalSpent = 0;
    double myContribution = 0;
    double foodSpent = 0;

    for (final c in costs) {
      final amt = (c['amount'] as num?)?.toDouble() ?? 0.0;
      totalSpent += amt;
      if (c['paid_by'] == _currentUserId) {
        myContribution += amt;
      }
      final cat = c['cost_categories'] as Map<String, dynamic>?;
      if (cat?['is_food'] == true) {
        foodSpent += amt;
      }
    }

    // 2. Meals in date range (no longer filtered by cycle_id)
    var mealQuery = _supabase
        .from('meal_logs')
        .select('user_id, breakfast, lunch, dinner')
        .eq('expense_account_id', houseId)
        .gte('log_date', startStr)
        .lte('log_date', endStr);

    final meals = await mealQuery;

    double totalMeals = 0;
    double myMeals = 0;

    for (final m in meals) {
      final b = (m['breakfast'] as num?)?.toDouble() ?? 0.0;
      final l = (m['lunch'] as num?)?.toDouble() ?? 0.0;
      final d = (m['dinner'] as num?)?.toDouble() ?? 0.0;
      final count = b + l + d;
      totalMeals += count;
      if (m['user_id'] == _currentUserId) {
        myMeals += count;
      }
    }

    final estimatedMealRate = totalMeals > 0 && foodSpent > 0
        ? foodSpent / totalMeals
        : 0.0;

    return {
      'totalSpent': totalSpent,
      'myContribution': myContribution,
      'foodSpent': foodSpent,
      'totalMeals': totalMeals,
      'myMeals': myMeals,
      'estimatedMealRate': estimatedMealRate,
    };
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      8,
      (i) => chars[(rand >> (i * 3)) % chars.length],
    ).join();
  }
}

