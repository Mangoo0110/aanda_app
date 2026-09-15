import 'package:aanda/src/features/house/domain/entities/house_member.dart';

class House {
  const House({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    this.members = const [],
  });

  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;

  /// Members are optionally populated when viewing house detail.
  final List<HouseMember> members;
}
