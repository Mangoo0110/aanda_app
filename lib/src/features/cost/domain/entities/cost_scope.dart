enum CostScope { personal, shared }

extension CostScopeX on CostScope {
  String get value => name;

  static CostScope fromString(String value) {
    return CostScope.values.firstWhere(
      (s) => s.name == value,
      orElse: () => CostScope.personal,
    );
  }
}
