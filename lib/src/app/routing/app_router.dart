import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/app/bloc/auth_guard/app_auth_guard_bloc.dart';
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
import 'package:aanda/src/features/auth/presentation/screens/views/welcome_view.dart';
import 'package:aanda/src/features/cost/domain/usecases/cost_usecases.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_feed/cost_feed_bloc.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_form/cost_form_bloc.dart';
import 'package:aanda/src/features/cost/presentation/screens/cost_feed_screen.dart';
import 'package:aanda/src/features/cost/presentation/screens/cost_form_screen.dart';
import 'package:aanda/src/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:aanda/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:aanda/src/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';
import 'package:aanda/src/features/house/presentation/bloc/house_detail/house_detail_bloc.dart';
import 'package:aanda/src/features/house/presentation/bloc/house_join/house_join_bloc.dart';
import 'package:aanda/src/features/house/presentation/screens/house_create_screen.dart';
import 'package:aanda/src/features/house/presentation/screens/house_detail_screen.dart';
import 'package:aanda/src/features/house/presentation/screens/house_join_screen.dart';

GoRouter createAppRouter({required AppAuthGuardBloc authGuardBloc}) {
  return GoRouter(
    initialLocation: AppRoutes.auth,
    refreshListenable: GoRouterRefreshStream(authGuardBloc.stream),
    redirect: (context, state) {
      final authStatus = authGuardBloc.state;
      final isAuthRoute = AppRoutes.isAuthRoute(state.uri.path);

      return switch (authStatus) {
        LoadingAuthSignature() => null,
        Authenticated() when isAuthRoute => AppRoutes.home,
        UnAuthenticated() when !isAuthRoute => AppRoutes.auth,
        _ => null,
      };
    },
    routes: [
      // ── Auth shell (guest-only routes) ────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => LoginBloc(
                  signInWithEmail: context.read<SignInWithEmail>(),
                ),
              ),
              BlocProvider(
                create: (_) => RegisterBloc(
                  signUpWithEmail: context.read<SignUpWithEmail>(),
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
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const WelcomeView(),
            ),
          ),
          GoRoute(
            path: AppRoutes.authLogin,
            name: 'auth-login',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const LoginNameView(),
            ),
          ),
          GoRoute(
            path: AppRoutes.authRegister,
            name: 'auth-register',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const CreateAccountView(),
            ),
          ),
        ],
      ),

      // ── Dashboard (authenticated) ──────────────────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: AuthRouteGate(
            policy: AuthRoutePolicy.signedInOnly,
            child: BlocProvider(
              create: (_) => DashboardBloc(
                getDashboardSummary: context.read<GetDashboardSummary>(),
              )..add(const DashboardStarted()),
              child: const DashboardScreen(),
            ),
          ),
        ),
      ),

      // ── Expenses Feed (authenticated) ───────────────────────────────────────
      GoRoute(
        path: AppRoutes.costs,
        name: 'costs',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: AuthRouteGate(
            policy: AuthRoutePolicy.signedInOnly,
            child: BlocProvider(
              create: (_) => CostFeedBloc(
                getCosts: context.read<GetCosts>(),
                deleteCost: context.read<DeleteCost>(),
              )..add(const CostFeedStarted()),
              child: const CostFeedScreen(),
            ),
          ),
        ),
      ),

      // ── Add Expense (modal / page) ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.costAdd,
        name: 'cost-add',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          fullscreenDialog: true,
          child: AuthRouteGate(
            policy: AuthRoutePolicy.signedInOnly,
            child: BlocProvider(
              create: (_) => CostFormBloc(
                addCost: context.read<AddCost>(),
                updateCost: context.read<UpdateCost>(),
                getCostCategories: context.read<GetCostCategories>(),
              ),
              child: const CostFormScreen(),
            ),
          ),
        ),
      ),
      // ── Create Shared House (page) ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.houseCreate,
        name: 'house-create',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AuthRouteGate(
            policy: AuthRoutePolicy.signedInOnly,
            child: HouseCreateScreen(),
          ),
        ),
      ),

      // ── Join Shared House ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.houseJoin,
        name: 'house-join',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: AuthRouteGate(
            policy: AuthRoutePolicy.signedInOnly,
            child: BlocProvider(
              create: (_) => HouseJoinBloc(
                joinHouse: context.read<JoinHouse>(),
              ),
              child: const HouseJoinScreen(),
            ),
          ),
        ),
      ),

      // ── House Detail ───────────────────────────────────────────────────────
      GoRoute(
        path: '/houses/:houseId',
        name: 'house-detail',
        pageBuilder: (context, state) {
          final houseId = state.pathParameters['houseId'] ?? '';
          return MaterialPage(
            key: state.pageKey,
            child: AuthRouteGate(
              policy: AuthRoutePolicy.signedInOnly,
              child: BlocProvider(
                create: (_) => HouseDetailBloc(
                  houseId: houseId,
                  getHouseDetail: context.read<GetHouseDetail>(),
                  getHouseInvite: context.read<GetHouseInvite>(),
                  regenerateInviteCode: context.read<RegenerateInviteCode>(),
                  leaveHouse: context.read<LeaveHouse>(),
                  removeMember: context.read<RemoveMember>(),
                ),
                child: HouseDetailScreen(houseId: houseId),
              ),
            ),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => const SizedBox.shrink(),
  );
}
