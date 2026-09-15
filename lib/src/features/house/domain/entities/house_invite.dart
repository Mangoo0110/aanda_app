class HouseInvite {
  const HouseInvite({
    required this.code,
    required this.houseId,
    this.expiresAt,
    this.createdAt,
  });

  final String code;
  final String houseId;
  final DateTime? expiresAt;
  final DateTime? createdAt;
}
