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
  });

  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final AccountType accountType;

  /// Members are optionally populated when viewing house detail.
  final List<HouseMember> members;

  bool get isPersonal => accountType == AccountType.personal;
  bool get isShared => accountType == AccountType.shared;
}
