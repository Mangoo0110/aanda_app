part of 'register_bloc.dart';

sealed class RegisterEvent {}

final class RegisterEmailChanged extends RegisterEvent {
  RegisterEmailChanged(this.email);
  final String email;
}

final class RegisterFullNameChanged extends RegisterEvent {
  RegisterFullNameChanged(this.fullName);
  final String fullName;
}

final class RegisterPasswordChanged extends RegisterEvent {
  RegisterPasswordChanged(this.password);
  final String password;
}

final class RegisterSubmitted extends RegisterEvent {}
