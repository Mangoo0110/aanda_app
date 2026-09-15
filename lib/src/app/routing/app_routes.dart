class AppRoutes {
  const AppRoutes._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const auth = '/auth';
  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';

  // ── Authenticated ─────────────────────────────────────────────────────────
  static const home = '/home';

  // ── House (Phase 2) ───────────────────────────────────────────────────────
  // static const houseCreate = '/home/create-house';
  // static const houseJoin   = '/home/join-house';

  static bool isAuthRoute(String path) {
    return path == auth || path.startsWith('$auth/');
  }
}
