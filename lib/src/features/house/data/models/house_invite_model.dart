import 'package:aanda/src/features/house/domain/entities/house_invite.dart';

class HouseInviteModel extends HouseInvite {
  const HouseInviteModel({
    required super.code,
    required super.houseId,
    super.expiresAt,
    super.createdAt,
  });

  factory HouseInviteModel.fromJson(Map<String, dynamic> json) {
    return HouseInviteModel(
      code: (json['invite_code'] ?? json['code']) as String,
      houseId: (json['house_id'] ?? json['id'] ?? '') as String,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'invite_code': code,
    'house_id': houseId,
    if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}
