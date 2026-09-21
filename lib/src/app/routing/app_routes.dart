class AppRoutes {
  const AppRoutes._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const auth = '/auth';
  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';
  static const authForgotPassword = '/auth/forgot-password';
  static const authResetPassword = '/auth/reset-password';

  // ── Home / Expenses & Houses ──────────────────────────────────────────────
  static const home = '/home';
  static const costs = '/costs';
  static const costAdd = '/costs/add';
  static const costCategoryAdd = '/costs/categories/new';
  static const houseCreate = '/houses/create';
  static const houseJoin = '/houses/join';
  static const meals = '/meals';
  static String houseDetail(String houseId) => '/houses/$houseId';
  static String houseMeals(String houseId) => '/houses/$houseId/meals';
  static String settlementStart(String houseId) => '/houses/$houseId/settlement';
  static String settlementHistory(String houseId) => '/houses/$houseId/settlements';

  static bool isAuthRoute(String path) {
    return path == auth || path.startsWith('$auth/');
  }
}
