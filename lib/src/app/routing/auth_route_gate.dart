import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/app/bloc/auth_guard/app_auth_guard_bloc.dart';
import 'package:aanda/src/app/view/app_splash_view.dart';
import 'package:aanda/src/features/auth/domain/entities/auth_status.dart';

enum AuthRoutePolicy { guestOnly, signedInOnly }

class AuthRouteGate extends StatelessWidget {
  const AuthRouteGate({super.key, required this.policy, required this.child});

  final AuthRoutePolicy policy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppAuthGuardBloc, AuthStatus>(
      buildWhen: _shouldBuildGate,
      builder: (context, state) {
        final shouldHideRoute = switch ((policy, state)) {
          (_, LoadingAuthSignature()) => true,
          (AuthRoutePolicy.guestOnly, Authenticated()) => true,
          (AuthRoutePolicy.signedInOnly, UnAuthenticated()) => true,
          _ => false,
        };

        if (shouldHideRoute) return const AppSplashView();
        return child;
      },
    );
  }

  bool _shouldBuildGate(AuthStatus previous, AuthStatus current) {
    if (previous.runtimeType != current.runtimeType) return true;
    return false;
  }
}

class AuthenticatedAccountRoute extends StatelessWidget {
  const AuthenticatedAccountRoute({super.key, required this.builder});

  final Widget Function(BuildContext context, String accountName) builder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppAuthGuardBloc, AuthStatus>(
      buildWhen: _shouldBuild,
      builder: (context, state) {
        if (state is! Authenticated) {
          return const AppSplashView();
        }

        return builder(context, state.account.uniqueName);
      },
    );
  }

  bool _shouldBuild(AuthStatus previous, AuthStatus current) {
    if (previous.runtimeType != current.runtimeType) return true;
    if (previous is Authenticated && current is Authenticated) {
      return previous.account.uniqueName != current.account.uniqueName;
    }
    return false;
  }
}
