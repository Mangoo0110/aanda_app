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
import 'package:aanda/src/features/auth/presentation/screens/views/forgot_password_view.dart';
import 'package:aanda/src/features/auth/presentation/screens/views/login_name_view.dart';
import 'package:aanda/src/features/auth/presentation/screens/views/reset_password_view.dart';
import 'package:aanda/src/features/auth/presentation/screens/views/welcome_view.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/domain/usecases/cost_usecases.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_feed/cost_feed_bloc.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_form/cost_form_bloc.dart';
import 'package:aanda/src/features/cost/presentation/screens/cost_category_form_screen.dart';
import 'package:aanda/src/features/cost/presentation/screens/cost_feed_screen.dart';
import 'package:aanda/src/features/cost/presentation/screens/cost_form_screen.dart';
import 'package:aanda/src/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:aanda/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:aanda/src/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';
import 'package:aanda/src/features/house/presentation/bloc/house_create/house_create_bloc.dart';
import 'package:aanda/src/features/house/presentation/bloc/house_detail/house_detail_bloc.dart';
import 'package:aanda/src/features/house/presentation/bloc/house_join/house_join_bloc.dart';
import 'package:aanda/src/features/house/presentation/screens/house_create_screen.dart';
import 'package:aanda/src/features/house/presentation/screens/house_detail_screen.dart';
import 'package:aanda/src/features/house/presentation/screens/house_join_screen.dart';
import 'package:aanda/src/features/meal/domain/usecases/meal_usecases.dart';
import 'package:aanda/src/features/meal/presentation/bloc/house_meals/house_meals_bloc.dart';
import 'package:aanda/src/features/meal/presentation/screens/house_meals_screen.dart';
import 'package:aanda/src/features/meal/presentation/screens/house_meals_tab_screen.dart';
import 'package:aanda/src/features/settlement/domain/usecases/settlement_usecases.dart';
import 'package:aanda/src/features/settlement/presentation/bloc/settlement_bloc.dart';
import 'package:aanda/src/features/settlement/presentation/screens/settlement_screen.dart';
import 'package:aanda/src/features/settlement/presentation/screens/settlement_history_screen.dart';
import 'package:aanda/src/features/settlement/presentation/screens/settlement_tab_screen.dart';
import 'package:aanda/src/features/auth/presentation/screens/account_screen.dart';
import 'package:aanda/src/features/auth/presentation/screens/splash_screen.dart';
import 'package:aanda/src/features/profile/presentation/screens/profile_onboarding_screen.dart';
import 'package:aanda/src/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:aanda/src/app/view/app_shell_scaffold.dart';

GoRouter createAppRouter({required AppAuthGuardBloc authGuardBloc}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authGuardBloc.stream),
    redirect: (context, state) {
      final authStatus = authGuardBloc.state;
      final path = state.uri.path;
      final isSplash = path == AppRoutes.splash;
      final isAuthRoute = AppRoutes.isAuthRoute(path);
      final isResetPassword = path == AppRoutes.authResetPassword;

      if (isSplash) return null;

      return switch (authStatus) {
        LoadingAuthSignature() => null,
        Authenticated() when isAuthRoute && !isResetPassword =>
          AppRoutes.splash,
        UnAuthenticated() when !isAuthRoute => AppRoutes.auth,
        _ => null,
      };
    },
    routes: [
      // ── Splash ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      // ── Profile Onboarding ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.profileOnboarding,
        name: 'profile-onboarding',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AuthRouteGate(
            policy: AuthRoutePolicy.signedInOnly,
            child: ProfileOnboardingScreen(),
          ),
        ),
      ),
      // ── Profile Edit ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.profileEdit,
        name: 'profile-edit',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AuthRouteGate(
            policy: AuthRoutePolicy.signedInOnly,
            child: ProfileEditScreen(),
          ),
        ),
      ),
      // ── Auth shell (guest-only routes) ────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    LoginBloc(signInWithEmail: context.read<SignInWithEmail>()),
              ),
              BlocProvider(
                create: (_) => RegisterBloc(
                  signUpWithEmail: context.read<SignUpWithEmail>(),
                  resendEmailVerification:
                      context.read<ResendEmailVerification>(),
                ),
              ),
            ],
            child: AuthShell(routePath: state.uri.path, child: child),
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.auth,
            name: 'auth-welcome',
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
          GoRoute(
            path: AppRoutes.authForgotPassword,
            name: 'auth-forgot-password',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: ForgotPasswordView(
                initialEmail: state.extra as String?,
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.authResetPassword,
            name: 'auth-reset-password',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ResetPasswordView(),
            ),
          ),
        ],
      ),

      // ── Main Authenticated Tab Shell ──────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AuthRouteGate(
            policy: AuthRoutePolicy.signedInOnly,
            child: AppShellScaffold(
              navigationShell: navigationShell,
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: BlocProvider(
                    create: (_) => DashboardBloc(
                      getDashboardSummary: context.read<GetDashboardSummary>(),
                      getSprints: context.read<GetSprints>(),
                      getHouseMembers: context.read<GetHouseMembers>(),
                      getMealLogs: context.read<GetMealLogs>(),
                      getCosts: context.read<GetCosts>(),
                    )..add(const DashboardStarted()),
                    child: const DashboardScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.costs,
                name: 'costs',
                pageBuilder: (context, state) {
                  final houseId = state.uri.queryParameters['houseId'];
                  final cycleId = state.uri.queryParameters['cycleId'];
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: BlocProvider(
                      create: (_) => CostFeedBloc(
                        getCosts: context.read<GetCosts>(),
                        deleteCost: context.read<DeleteCost>(),
                        getCostCategories: context.read<GetCostCategories>(),
                        getSprints: context.read<GetSprints>(),
                        initialHouseId: houseId,
                        initialCycleId: cycleId,
                      )..add(const CostFeedStarted()),
                      child: const CostFeedScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.mealsTab,
                name: 'meals-tab',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const HouseMealsTabScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settlement,
                name: 'settlement',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: BlocProvider(
                    create: (_) => SettlementBloc(
                      prepareSettlement: context.read<PrepareSettlement>(),
                      computeSettlement: context.read<ComputeSettlement>(),
                      finaliseSettlement: context.read<FinaliseSettlement>(),
                      getSettlements: context.read<GetSettlements>(),
                      recordSettlementPayment:
                          context.read<RecordSettlementPayment>(),
                      finaliseSettlementWithResolutions:
                          context.read<FinaliseSettlementWithResolutions>(),
                    ),
                    child: const SettlementTabScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.account,
                name: 'account',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const AccountScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Add Expense (modal / page) ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.costAdd,
        name: 'cost-add',
        pageBuilder: (context, state) {
          final extra = state.extra;
          Cost? initialCost;
          CostCategory? categoryPreset;
          CostScope? initialScope;
          String? initialHouseId = state.uri.queryParameters['houseId'];
          final categoryId = state.uri.queryParameters['categoryId'];

          if (extra is Cost) {
            initialCost = extra;
          } else if (extra is CostCategory) {
            categoryPreset = extra;
          } else if (extra is Map<String, dynamic>) {
            if (extra['cost'] is Cost) initialCost = extra['cost'] as Cost;
            if (extra['category'] is CostCategory) {
              categoryPreset = extra['category'] as CostCategory;
            }
            if (extra['categoryPreset'] is CostCategory) {
              categoryPreset = extra['categoryPreset'] as CostCategory;
            }
            if (extra.containsKey('houseId')) {
              initialHouseId = extra['houseId'] as String?;
            }
            if (extra['scope'] is CostScope) {
              initialScope = extra['scope'] as CostScope;
            }
          }

          return MaterialPage(
            key: state.pageKey,
            fullscreenDialog: true,
            child: AuthRouteGate(
              policy: AuthRoutePolicy.signedInOnly,
              child: BlocProvider(
                create: (_) => CostFormBloc(
                  addCost: context.read<AddCost>(),
                  updateCost: context.read<UpdateCost>(),
                  getCostCategories: context.read<GetCostCategories>(),
                  getHouseMembers: context.read<GetHouseMembers>(),
                ),
                child: CostFormScreen(
                  initialCost: initialCost,
                  initialCategory: categoryPreset,
                  categoryPreset: categoryPreset,
                  initialCategoryId: categoryId,
                  initialHouseId: initialHouseId,
                  initialScope: initialScope,
                ),
              ),
            ),
          );
        },
      ),

      // ── Create Cost Category Preset (modal / page) ─────────────────────────
      GoRoute(
        path: AppRoutes.costCategoryAdd,
        name: 'cost-category-add',
        pageBuilder: (context, state) {
          final houseId = state.uri.queryParameters['houseId'];
          final houseName = state.uri.queryParameters['houseName'];
          return MaterialPage(
            key: state.pageKey,
            fullscreenDialog: true,
            child: AuthRouteGate(
              policy: AuthRoutePolicy.signedInOnly,
              child: CostCategoryFormScreen(
                initialHouseId: houseId,
                initialHouseName: houseName,
              ),
            ),
          );
        },
      ),
      // ── Create Shared House (page) ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.houseCreate,
        name: 'house-create',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: AuthRouteGate(
            policy: AuthRoutePolicy.signedInOnly,
            child: BlocProvider(
              create: (_) => HouseCreateBloc(
                createHouse: context.read<CreateHouse>(),
                uploadHouseAvatar: context.read<UploadHouseAvatar>(),
              ),
              child: const HouseCreateScreen(),
            ),
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
              create: (_) =>
                  HouseJoinBloc(joinHouse: context.read<JoinHouse>()),
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
                  getSprintStats: context.read<GetSprintStats>(),
                ),
                child: HouseDetailScreen(houseId: houseId),
              ),
            ),
          );
        },
      ),

      // ── Settlement Start (full screen wizard) ─────────────────────────────
      GoRoute(
        path: '/houses/:houseId/settlement',
        name: 'settlement-start',
        pageBuilder: (context, state) {
          final houseId = state.pathParameters['houseId'] ?? '';
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final houseName = extra['houseName'] as String? ?? 'Account';
          final isAdmin = extra['isAdmin'] as bool? ?? false;
          return MaterialPage(
            key: state.pageKey,
            child: AuthRouteGate(
              policy: AuthRoutePolicy.signedInOnly,
              child: BlocProvider(
                create: (_) => SettlementBloc(
                  prepareSettlement: context.read<PrepareSettlement>(),
                  computeSettlement: context.read<ComputeSettlement>(),
                  finaliseSettlement: context.read<FinaliseSettlement>(),
                  getSettlements: context.read<GetSettlements>(),
                  recordSettlementPayment:
                      context.read<RecordSettlementPayment>(),
                  finaliseSettlementWithResolutions:
                      context.read<FinaliseSettlementWithResolutions>(),
                )..add(SettlementStarted(houseId: houseId, isAdmin: isAdmin)),
                child: SettlementScreen(
                  houseId: houseId,
                  houseName: houseName,
                  isAdmin: isAdmin,
                ),
              ),
            ),
          );
        },
      ),

      // ── Settlement History ────────────────────────────────────────────────
      GoRoute(
        path: '/houses/:houseId/settlements',
        name: 'settlement-history',
        pageBuilder: (context, state) {
          final houseId = state.pathParameters['houseId'] ?? '';
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final houseName = extra['houseName'] as String? ?? 'Account';
          final isAdmin = extra['isAdmin'] as bool? ?? false;
          return MaterialPage(
            key: state.pageKey,
            child: AuthRouteGate(
              policy: AuthRoutePolicy.signedInOnly,
              child: BlocProvider(
                create: (_) => SettlementBloc(
                  prepareSettlement: context.read<PrepareSettlement>(),
                  computeSettlement: context.read<ComputeSettlement>(),
                  finaliseSettlement: context.read<FinaliseSettlement>(),
                  getSettlements: context.read<GetSettlements>(),
                  recordSettlementPayment:
                      context.read<RecordSettlementPayment>(),
                  finaliseSettlementWithResolutions:
                      context.read<FinaliseSettlementWithResolutions>(),
                ),
                child: SettlementHistoryScreen(
                  houseId: houseId,
                  houseName: houseName,
                  isAdmin: isAdmin,
                ),
              ),
            ),
          );
        },
      ),

      // ── House Meals Spreadsheet ────────────────────────────────────────────
      GoRoute(
        path: '/houses/:houseId/meals',
        name: 'house-meals',
        pageBuilder: (context, state) {
          final houseId = state.pathParameters['houseId'] ?? '';
          final cycleId = state.uri.queryParameters['cycleId'] ?? '';
          final sprint = state.extra is Sprint ? state.extra as Sprint : null;
          return MaterialPage(
            key: state.pageKey,
            child: AuthRouteGate(
              policy: AuthRoutePolicy.signedInOnly,
              child: BlocProvider(
                create: (_) => HouseMealsBloc(
                  houseId: houseId,
                  cycleId: cycleId,
                  getHouseMembers: context.read<GetHouseMembers>(),
                  getMealLogs: context.read<GetMealLogs>(),
                  upsertMealLog: context.read<UpsertMealLog>(),
                  getSprints: context.read<GetSprints>(),
                )..add(const HouseMealsStarted()),
                child: HouseMealsScreen(
                  houseId: houseId,
                  cycleId: cycleId,
                  sprint: sprint,
                ),
              ),
            ),
          );
        },
      ),

      // ── General Meals Shortcut Route ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.meals,
        name: 'meals',
        pageBuilder: (context, state) {
          final houseId = state.uri.queryParameters['houseId'] ?? 'default';
          final cycleId = state.uri.queryParameters['cycleId'] ?? '';
          final sprint = state.extra is Sprint ? state.extra as Sprint : null;
          return MaterialPage(
            key: state.pageKey,
            child: AuthRouteGate(
              policy: AuthRoutePolicy.signedInOnly,
              child: BlocProvider(
                create: (_) => HouseMealsBloc(
                  houseId: houseId,
                  cycleId: cycleId,
                  getHouseMembers: context.read<GetHouseMembers>(),
                  getMealLogs: context.read<GetMealLogs>(),
                  upsertMealLog: context.read<UpsertMealLog>(),
                  getSprints: context.read<GetSprints>(),
                )..add(const HouseMealsStarted()),
                child: HouseMealsScreen(
                  houseId: houseId,
                  cycleId: cycleId,
                  sprint: sprint,
                ),
              ),
            ),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => const SizedBox.shrink(),
  );
}
