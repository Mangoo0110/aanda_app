class AppRoutes {
  const AppRoutes._();

  static const auth = '/auth';
  static const authLogin = '/auth/login';
  static const authPin = '/auth/login/pin';
  static const authRegister = '/auth/register';

  static const entryFeed = '/entry-feed';
  static const entryDetail = '/entry-feed/detail';
  static const entryForm = '/entry-feed/form';

  static bool isAuthRoute(String path) {
    return path == auth || path.startsWith('$auth/');
  }
}
