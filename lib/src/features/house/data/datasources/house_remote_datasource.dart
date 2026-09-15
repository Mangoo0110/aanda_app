import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/features/house/data/models/house_invite_model.dart';
import 'package:aanda/src/features/house/data/models/house_member_model.dart';
import 'package:aanda/src/features/house/data/models/house_model.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/entities/house_invite.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';

/// Supabase-backed datasource for the `houses` and `house_members` tables.
class HouseRemoteDatasource {
  HouseRemoteDatasource({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  String get _currentUserId =>
      _supabase.auth.currentUser?.id ?? (throw Exception('Not authenticated'));

  // ── Houses ─────────────────────────────────────────────────────────────────

  Future<House> createHouse({required String name}) async {
    final data = await _supabase
        .from('houses')
        .insert({'name': name, 'created_by': _currentUserId})
        .select()
        .single();

    final house = HouseModel.fromJson(data);

    // Insert the creator as admin member.
    await _supabase.from('house_members').insert({
      'house_id': house.id,
      'user_id': _currentUserId,
      'role': 'admin',
    });

    return house;
  }

  Future<House> joinHouse({required String inviteCode}) async {
    // Find the house by invite code.
    final houseData = await _supabase
        .from('houses')
        .select()
        .eq('invite_code', inviteCode.trim().toUpperCase())
        .maybeSingle();

    if (houseData == null) {
      throw Exception('House not found. Check the invite code and try again.');
    }

    final house = HouseModel.fromJson(houseData);

    // Check not already a member.
    final existing = await _supabase
        .from('house_members')
        .select('id')
        .eq('house_id', house.id)
        .eq('user_id', _currentUserId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('You are already a member of this house.');
    }

    await _supabase.from('house_members').insert({
      'house_id': house.id,
      'user_id': _currentUserId,
      'role': 'member',
    });

    return house;
  }

  Future<List<House>> getMyHouses() async {
    final rows = await _supabase
        .from('house_members')
        .select('house_id, houses(*)')
        .eq('user_id', _currentUserId);

    return rows
        .map((r) => HouseModel.fromJson(r['houses'] as Map<String, dynamic>))
        .toList();
  }

  Future<House> getHouseDetail({required String houseId}) async {
    final houseData = await _supabase
        .from('houses')
        .select()
        .eq('id', houseId)
        .single();

    final members = await getHouseMembers(houseId: houseId);
    return HouseModel.fromJsonWithMembers(houseData, members);
  }

  // ── Invites ────────────────────────────────────────────────────────────────

  Future<HouseInvite> getHouseInvite({required String houseId}) async {
    final data = await _supabase
        .from('houses')
        .select('id, invite_code')
        .eq('id', houseId)
        .single();

    return HouseInviteModel.fromJson(data);
  }

  Future<HouseInvite> regenerateInviteCode({required String houseId}) async {
    final newCode = _generateCode();
    await _supabase
        .from('houses')
        .update({'invite_code': newCode})
        .eq('id', houseId);
    return HouseInviteModel(code: newCode, houseId: houseId);
  }

  // ── Members ────────────────────────────────────────────────────────────────

  Future<List<HouseMember>> getHouseMembers({required String houseId}) async {
    final rows = await _supabase
        .from('house_members')
        .select('*, profiles(username, full_name, avatar_url)')
        .eq('house_id', houseId)
        .order('joined_at');

    return rows.map((r) => HouseMemberModel.fromJson(r)).toList();
  }

  Future<void> leaveHouse({required String houseId}) async {
    await _supabase
        .from('house_members')
        .delete()
        .eq('house_id', houseId)
        .eq('user_id', _currentUserId);
  }

  Future<void> removeMember({
    required String houseId,
    required String userId,
  }) async {
    await _supabase
        .from('house_members')
        .delete()
        .eq('house_id', houseId)
        .eq('user_id', userId);
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
