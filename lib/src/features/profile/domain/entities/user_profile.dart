class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.country,
    this.gender,
    this.ageRange,
    this.isOnboarded = false,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? country;
  final String? gender;
  final String? ageRange;
  final bool isOnboarded;
  final DateTime? updatedAt;

  /// Profile is complete if the user completed onboarding or has demographic fields populated.
  bool get isComplete {
    if (isOnboarded) return true;
    return (country != null && country!.isNotEmpty) &&
        (gender != null && gender!.isNotEmpty) &&
        (ageRange != null && ageRange!.isNotEmpty);
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? country,
    String? gender,
    String? ageRange,
    bool? isOnboarded,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      country: country ?? this.country,
      gender: gender ?? this.gender,
      ageRange: ageRange ?? this.ageRange,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserProfile.empty() {
    return const UserProfile(
      id: '',
      email: '',
      username: '',
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? email}) {
    return UserProfile(
      id: map['id'] as String? ?? '',
      email: email ?? (map['email'] as String? ?? ''),
      username: map['username'] as String? ?? '',
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      country: map['country'] as String?,
      gender: map['gender'] as String?,
      ageRange: map['age_range'] as String?,
      isOnboarded: map['is_onboarded'] as bool? ?? false,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      if (fullName != null) 'full_name': fullName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (country != null) 'country': country,
      if (gender != null) 'gender': gender,
      if (ageRange != null) 'age_range': ageRange,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
