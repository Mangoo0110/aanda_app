import 'package:aanda/src/features/house/domain/entities/house_member.dart';

enum AccountType { personal, shared }

typedef ExpenseAccount = House;

class House {
  const House({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    this.accountType = AccountType.shared,
    this.members = const [],
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final AccountType accountType;

  /// Members are optionally populated when viewing house detail.
  final List<HouseMember> members;

  /// Optional avatar / logo for the house
  final String? avatarUrl;

  bool get isPersonal => accountType == AccountType.personal;
  bool get isShared => accountType == AccountType.shared;

  House copyWith({
    String? id,
    String? name,
    String? createdBy,
    DateTime? createdAt,
    AccountType? accountType,
    List<HouseMember>? members,
    String? avatarUrl,
  }) {
    return House(
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
