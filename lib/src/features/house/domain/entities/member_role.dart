enum MemberRole { admin, member }

extension MemberRoleX on MemberRole {
  String get value => name; // 'admin' | 'member'

  static MemberRole fromString(String value) {
    return MemberRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => MemberRole.member,
    );
  }
}
