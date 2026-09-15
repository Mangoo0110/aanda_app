class SignInParams {
  const SignInParams({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

class SignUpParams {
  const SignUpParams({
    required this.email,
    required this.password,
    this.fullName,
  });

  final String email;
  final String password;
  final String? fullName;
}
