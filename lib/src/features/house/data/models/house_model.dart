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
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'account_type': accountType.name,
  };
}
