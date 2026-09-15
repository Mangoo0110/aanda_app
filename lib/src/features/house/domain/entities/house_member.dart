import 'package:aanda/src/features/house/domain/entities/member_role.dart';

class HouseMember {
  const HouseMember({
    required this.id,
    required this.houseId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.username,
    this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String houseId;
  final String userId;
  final MemberRole role;
  final DateTime joinedAt;

  /// Denormalised profile fields — populated via join queries.
  final String? username;
  final String? fullName;
  final String? avatarUrl;

  String get displayName => fullName ?? username ?? userId;

  bool get isAdmin => role == MemberRole.admin;
}
