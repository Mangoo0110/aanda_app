import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';

class HouseModel extends House {
  const HouseModel({
    required super.id,
    required super.name,
    required super.createdBy,
    required super.createdAt,
    super.accountType,
    super.members,
    super.avatarUrl,
  });

  factory HouseModel.fromJson(Map<String, dynamic> json) {
    return HouseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      accountType: json['account_type'] == 'personal'
          ? AccountType.personal
          : AccountType.shared,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  factory HouseModel.fromJsonWithMembers(
    Map<String, dynamic> json,
    List<HouseMember> members,
  ) {
    return HouseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      accountType: json['account_type'] == 'personal'
          ? AccountType.personal
          : AccountType.shared,
      members: members,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'account_type': accountType.name,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
  };

  @override
  HouseModel copyWith({
    String? id,
    String? name,
    String? createdBy,
    DateTime? createdAt,
    AccountType? accountType,
    List<HouseMember>? members,
    String? avatarUrl,
  }) {
    return HouseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      accountType: accountType ?? this.accountType,
      members: members ?? this.members,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
