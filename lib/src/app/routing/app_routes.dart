class AppRoutes {
  const AppRoutes._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const auth = '/auth';
  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';

  // ── Home / Expenses & Houses ──────────────────────────────────────────────
  static const home = '/home';
  static const costs = '/costs';
  static const costAdd = '/costs/add';
  static const houseCreate = '/houses/create';
  static const houseJoin = '/houses/join';
  static String houseDetail(String houseId) => '/houses/$houseId';
  static String houseMeals(String houseId) => '/houses/$houseId/meals';

  static bool isAuthRoute(String path) {
    return path == auth || path.startsWith('$auth/');
  }
}
