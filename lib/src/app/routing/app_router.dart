import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/app/bloc/auth_guard/app_auth_guard_bloc.dart';
import 'package:aanda/src/app/view/user_dashboard_view.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/app/routing/auth_route_gate.dart';
import 'package:aanda/src/app/routing/go_router_refresh_stream.dart';
import 'package:aanda/src/features/auth/domain/entities/auth_status.dart';
import 'package:aanda/src/features/auth/domain/usecases/auth_usecases.dart';
import 'package:aanda/src/features/auth/presentation/bloc/login/login_bloc.dart';
import 'package:aanda/src/features/auth/presentation/bloc/register/register_bloc.dart';
import 'package:aanda/src/features/auth/presentation/screens/auth_shell.dart';
import 'package:aanda/src/features/auth/presentation/screens/views/create_account_view.dart';
import 'package:aanda/src/features/auth/presentation/screens/views/login_name_view.dart';
import 'package:aanda/src/features/auth/presentation/screens/views/pin_unlock_view.dart';
import 'package:aanda/src/features/auth/presentation/screens/views/welcome_view.dart';
import 'package:aanda/src/features/entry/presentation/view/entry_detail/entry_detail_screen.dart';
import 'package:aanda/src/features/entry/presentation/view/entry_form/entry_form_screen.dart';
import 'package:aanda/src/features/entry/presentation/view/entry_form/entry_form_view.dart';

GoRouter createAppRouter({required AppAuthGuardBloc authGuardBloc}) {
  return GoRouter(
    initialLocation: AppRoutes.auth,
    refreshListenable: GoRouterRefreshStream(authGuardBloc.stream),
    redirect: (context, state) {
      final authStatus = authGuardBloc.state;
      final isAuthRoute = AppRoutes.isAuthRoute(state.uri.path);

      return switch (authStatus) {
        LoadingAuthSignature() => null,
        Authenticated() when isAuthRoute => AppRoutes.entryFeed,
        UnAuthenticated() when !isAuthRoute => AppRoutes.auth,
        _ => null,
      };
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => LoginBloc(
                  isAccountNameAvailable: context
                      .read<IsAccountNameAvailable>(),
                  unlockAccount: context.read<UnlockAccount>(),
                ),
              ),
              BlocProvider(
                create: (_) => RegisterBloc(
                  isAccountNameAvailable: context
                      .read<IsAccountNameAvailable>(),
                  createAccount: context.read<CreateAccount>(),
                ),
              ),
            ],
            child: AuthRouteGate(
              policy: AuthRoutePolicy.guestOnly,
              child: AuthShell(routePath: state.uri.path, child: child),
            ),
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.auth,
            name: 'auth',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                key: state.pageKey,
                child: const WelcomeView(),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.authLogin,
            name: 'auth-login',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                key: state.pageKey,
                child: const LoginNameView(),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.authPin,
            name: 'auth-pin',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                key: state.pageKey,
                child: const PinUnlockView(),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.authRegister,
            name: 'auth-register',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                key: state.pageKey,
                child: const CreateAccountView(),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.entryFeed,
        name: 'entry-feed',
        pageBuilder: (context, state) {
          return NoTransitionPage(
            key: state.pageKey,
            child: AuthRouteGate(
              policy: AuthRoutePolicy.signedInOnly,
              child: AuthenticatedAccountRoute(
                builder: (context, accountName) {
                  return UserDashboardView(accountName: accountName);
                },
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.entryDetail,
        name: 'entry-detail',
        pageBuilder: (context, state) {
          return NoTransitionPage(
            key: state.pageKey,
            child: AuthRouteGate(
              policy: AuthRoutePolicy.signedInOnly,
              child: AuthenticatedAccountRoute(
                builder: (context, accountName) {
                  final entryId = int.tryParse(
                    state.uri.queryParameters['entryId'] ?? '',
                  );
                  if (entryId == null) return const SizedBox.shrink();
                  return EntryDetailScreen(
                    accountName: accountName,
                    entryId: entryId,
                  );
                },
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.entryForm,
        name: 'entry-form',
        pageBuilder: (context, state) {
          return NoTransitionPage(
            key: state.pageKey,
            child: AuthRouteGate(
              policy: AuthRoutePolicy.signedInOnly,
              child: AuthenticatedAccountRoute(
                builder: (context, accountName) {
                  final entryId = int.tryParse(
                    state.uri.queryParameters['entryId'] ?? '',
                  );
                  return EntryFormScreen(
                    accountName: accountName,
                    mode: entryId == null
                        ? EntryFormMode.create
                        : EntryFormMode.edit,
                    entryId: entryId,
                  );
                },
              ),
            ),
          );
        },
      ),
    ],
    errorBuilder: (context, state) {
      return const SizedBox.shrink();
    },
  );
}
