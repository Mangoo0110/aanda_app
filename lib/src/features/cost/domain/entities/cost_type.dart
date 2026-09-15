enum CostType { variable, fixed }

extension CostTypeX on CostType {
  String get value => name;

  static CostType fromString(String value) {
    return CostType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => CostType.variable,
    );
  }
}
