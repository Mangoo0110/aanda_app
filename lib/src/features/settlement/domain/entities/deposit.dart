enum DepositType {
  advance,
  settlementDue,
  costPayment,
}

extension DepositTypeX on DepositType {
  String get value => switch (this) {
        DepositType.advance => 'advance',
        DepositType.settlementDue => 'settlement_due',
        DepositType.costPayment => 'cost_payment',
      };

  static DepositType fromString(String val) => switch (val) {
        'advance' => DepositType.advance,
        'settlement_due' => DepositType.settlementDue,
        'cost_payment' => DepositType.costPayment,
        _ => DepositType.advance,
      };

  String get displayName => switch (this) {
        DepositType.advance => 'Advance Deposit',
        DepositType.settlementDue => 'Settlement Payment',
        DepositType.costPayment => 'Expense Contribution',
      };
}

class Deposit {
  const Deposit({
    required this.id,
    required this.houseId,
    required this.userId,
    this.settlementId,
    this.costId,
    required this.depositType,
    required this.amount,
    this.note,
    required this.depositDate,
    required this.recordedBy,
    required this.createdAt,
    this.userName,
    this.userAvatar,
  });

  final String id;
  final String houseId;
  final String userId;
  final String? settlementId;
  final String? costId;
  final DepositType depositType;
  final double amount;
  final String? note;
  final DateTime depositDate;
  final String recordedBy;
  final DateTime createdAt;
  final String? userName;
  final String? userAvatar;

  bool get isSettled => settlementId != null && settlementId!.isNotEmpty;

  factory Deposit.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return Deposit(
      id: json['id'] as String? ?? '',
      houseId: (json['expense_account_id'] ?? json['house_id'] ?? '') as String,
      userId: json['user_id'] as String? ?? '',
      settlementId: json['settlement_id'] as String?,
      costId: json['cost_id'] as String?,
      depositType: DepositTypeX.fromString(
        json['deposit_type'] as String? ?? 'advance',
      ),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String?,
      depositDate: json['deposit_date'] != null
          ? DateTime.tryParse(json['deposit_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      recordedBy: json['recorded_by'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      userName: profile?['full_name'] as String? ??
          profile?['username'] as String?,
      userAvatar: profile?['avatar_url'] as String?,
    );
  }
}
