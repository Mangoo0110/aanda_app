class AppRoutes {
  const AppRoutes._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const auth = '/auth';
  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';

  // ── Home / Expenses (Phase 2) ─────────────────────────────────────────────
  static const home = '/home';
  static const costAdd = '/costs/add';

  static bool isAuthRoute(String path) {
    return path == auth || path.startsWith('$auth/');
  }
}
