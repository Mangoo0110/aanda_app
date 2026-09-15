import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/entities/member_role.dart';

class HouseMemberModel extends HouseMember {
  const HouseMemberModel({
    required super.id,
    required super.houseId,
    required super.userId,
    required super.role,
    required super.joinedAt,
    super.username,
    super.fullName,
    super.avatarUrl,
  });

  /// Parses from a `house_members` row joined with `profiles`.
  ///
  /// Expected shape (Supabase select with join):
  /// ```json
  /// {
  ///   "id": "...",
  ///   "house_id": "...",
  ///   "user_id": "...",
  ///   "role": "admin",
  ///   "joined_at": "2024-01-01T00:00:00Z",
  ///   "profiles": { "username": "...", "full_name": "...", "avatar_url": "..." }
  /// }
  /// ```
  factory HouseMemberModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return HouseMemberModel(
      id: json['id'] as String,
      houseId: json['house_id'] as String,
      userId: json['user_id'] as String,
      role: MemberRoleX.fromString(json['role'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      username: profile?['username'] as String?,
      fullName: profile?['full_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }
}
