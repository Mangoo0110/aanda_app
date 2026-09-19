import 'account.dart';

sealed class AuthStatus {}

class Authenticated extends AuthStatus {
  final Account account;
  Authenticated(this.account);
}

class UnAuthenticated extends AuthStatus {}

class UnconfirmedEmail extends AuthStatus {
  final String email;
  UnconfirmedEmail({required this.email});
}

class LoadingAuthSignature extends AuthStatus {}
