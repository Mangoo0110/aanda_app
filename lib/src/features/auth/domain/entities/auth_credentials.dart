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
    required this.username,
    this.fullName,
  });

  final String email;
  final String password;
  final String username;
  final String? fullName;
}
