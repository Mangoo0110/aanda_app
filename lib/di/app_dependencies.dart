import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aanda/src/app/bloc/app_theme_cubit.dart';
import 'package:aanda/src/app/bloc/auth_guard/app_auth_guard_bloc.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';

// Auth
import 'package:aanda/src/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:aanda/src/features/auth/data/repo/auth_repo_impl.dart';
import 'package:aanda/src/features/auth/domain/repo/auth_repo.dart';
import 'package:aanda/src/features/auth/domain/usecases/auth_usecases.dart';

// Cost
import 'package:aanda/src/features/cost/data/datasources/category_emoji_local_datasource.dart';
import 'package:aanda/src/features/cost/data/datasources/category_emoji_remote_datasource.dart';
import 'package:aanda/src/features/cost/data/datasources/cost_remote_datasource.dart';
import 'package:aanda/src/features/cost/data/repo/category_emoji_repo_impl.dart';
import 'package:aanda/src/features/cost/data/repo/cost_repo_impl.dart';
import 'package:aanda/src/features/cost/domain/repo/category_emoji_repo.dart';
import 'package:aanda/src/features/cost/domain/repo/cost_repo.dart';
import 'package:aanda/src/features/cost/domain/usecases/cost_usecases.dart';

// House
import 'package:aanda/src/features/house/data/datasources/house_remote_datasource.dart';
import 'package:aanda/src/features/house/data/repo/house_repo_impl.dart';
import 'package:aanda/src/features/house/domain/repo/house_repo.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';

// Meal
import 'package:aanda/src/features/meal/data/datasources/meal_remote_datasource.dart';
import 'package:aanda/src/features/meal/data/repo/meal_repo_impl.dart';
import 'package:aanda/src/features/meal/domain/repo/meal_repo.dart';
import 'package:aanda/src/features/meal/domain/usecases/meal_usecases.dart';

// Settlement
import 'package:aanda/src/features/settlement/data/datasources/settlement_remote_datasource.dart';
import 'package:aanda/src/features/settlement/data/repo/settlement_repo_impl.dart';
import 'package:aanda/src/features/settlement/domain/repo/settlement_repo.dart';
import 'package:aanda/src/features/settlement/domain/usecases/settlement_usecases.dart';

// Dashboard
import 'package:aanda/src/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:aanda/src/features/dashboard/data/repo/dashboard_repo_impl.dart';
import 'package:aanda/src/features/dashboard/domain/repo/dashboard_repo.dart';
import 'package:aanda/src/features/dashboard/domain/usecases/dashboard_usecases.dart';

final class AppDependencies {
  const AppDependencies._({
    required this.supabase,
    // Auth
    required this.authDatasource,
    required this.authRepo,
    required this.watchAuthStatus,
    required this.signInWithEmail,
    required this.signUpWithEmail,
    required this.logout,
    required this.getCurrentAccount,
    required this.deleteAccount,
    required this.resendEmailVerification,
    required this.sendPasswordResetEmail,
    required this.verifyPasswordResetOtp,
    required this.resetPassword,
    // Cost
    required this.costDatasource,
    required this.costRepo,
    required this.getCosts,
    required this.addCost,
    required this.updateCost,
    required this.deleteCost,
    required this.getCostCategories,
    required this.createCostCategory,
    required this.categoryEmojiRemoteDatasource,
    required this.categoryEmojiLocalDatasource,
    required this.categoryEmojiRepo,
    required this.getCategoryEmojis,
    // House
    required this.houseDatasource,
    required this.houseRepo,
    required this.createHouse,
    required this.getMyHouses,
    required this.getHouseDetail,
    required this.getHouseMembers,
    required this.getHouseInvite,
    required this.regenerateInviteCode,
    required this.joinHouse,
    required this.leaveHouse,
    required this.removeMember,
    required this.getSprints,
    required this.createSprint,
    required this.closeSprint,
    required this.getSprintStats,
    // Meal
    required this.mealDatasource,
    required this.mealRepo,
    required this.getMealLogs,
    required this.upsertMealLog,
    // Settlement
    required this.settlementDatasource,
    required this.settlementRepo,
    required this.computeSettlement,
    required this.getCycleSettlement,
    // Dashboard
    required this.dashboardDatasource,
    required this.dashboardRepo,
    required this.getDashboardSummary,
    // Blocs
    required this.authGuardBloc,
    required this.appThemeCubit,
    required this.houseContextCubit,
  });

  final SupabaseClient supabase;

  // ── Auth ──────────────────────────────────────────────────────────────────
  final SupabaseAuthDatasource authDatasource;
  final AuthRepo authRepo;
  final WatchAuthStatus watchAuthStatus;
  final SignInWithEmail signInWithEmail;
  final SignUpWithEmail signUpWithEmail;
  final Logout logout;
  final GetCurrentAccount getCurrentAccount;
  final DeleteAccount deleteAccount;
  final ResendEmailVerification resendEmailVerification;
  final SendPasswordResetEmail sendPasswordResetEmail;
  final VerifyPasswordResetOtp verifyPasswordResetOtp;
  final ResetPassword resetPassword;

  // ── Cost ──────────────────────────────────────────────────────────────────
  final CostRemoteDatasource costDatasource;
  final CostRepo costRepo;
  final GetCosts getCosts;
  final AddCost addCost;
  final UpdateCost updateCost;
  final DeleteCost deleteCost;
  final GetCostCategories getCostCategories;
  final CreateCostCategory createCostCategory;
  final CategoryEmojiRemoteDatasource categoryEmojiRemoteDatasource;
  final CategoryEmojiLocalDatasource categoryEmojiLocalDatasource;
  final CategoryEmojiRepo categoryEmojiRepo;
  final GetCategoryEmojis getCategoryEmojis;

  // ── House ─────────────────────────────────────────────────────────────────
  final HouseRemoteDatasource houseDatasource;
  final HouseRepo houseRepo;
  final CreateHouse createHouse;
  final GetMyHouses getMyHouses;
  final GetHouseDetail getHouseDetail;
  final GetHouseMembers getHouseMembers;
  final GetHouseInvite getHouseInvite;
  final RegenerateInviteCode regenerateInviteCode;
  final JoinHouse joinHouse;
  final LeaveHouse leaveHouse;
  final RemoveMember removeMember;
  final GetSprints getSprints;
  final CreateSprint createSprint;
  final CloseSprint closeSprint;
  final GetSprintStats getSprintStats;

  // ── Meal ──────────────────────────────────────────────────────────────────
  final MealRemoteDatasource mealDatasource;
  final MealRepo mealRepo;
  final GetMealLogs getMealLogs;
  final UpsertMealLog upsertMealLog;

  // ── Settlement ────────────────────────────────────────────────────────────
  final SettlementRemoteDatasource settlementDatasource;
  final SettlementRepo settlementRepo;
  final ComputeSettlement computeSettlement;
  final GetCycleSettlement getCycleSettlement;

  // ── Dashboard ─────────────────────────────────────────────────────────────
  final DashboardRemoteDatasource dashboardDatasource;
  final DashboardRepo dashboardRepo;
  final GetDashboardSummary getDashboardSummary;

  // ── App blocs ─────────────────────────────────────────────────────────────
  final AppAuthGuardBloc authGuardBloc;
  final AppThemeCubit appThemeCubit;
  final HouseContextCubit houseContextCubit;

  static AppDependencies create({required SupabaseClient supabase}) {
    // Auth
    final authDatasource = SupabaseAuthDatasource(supabase: supabase);
    final authRepo = AuthRepoImpl(datasource: authDatasource);
    final watchAuthStatus = WatchAuthStatus(authRepo);
    final signInWithEmail = SignInWithEmail(authRepo);
    final signUpWithEmail = SignUpWithEmail(authRepo);
    final logout = Logout(authRepo);
    final getCurrentAccount = GetCurrentAccount(authRepo);
    final deleteAccount = DeleteAccount(authRepo);
    final resendEmailVerification = ResendEmailVerification(authRepo);
    final sendPasswordResetEmail = SendPasswordResetEmail(authRepo);
    final verifyPasswordResetOtp = VerifyPasswordResetOtp(authRepo);
    final resetPassword = ResetPassword(authRepo);

    // Cost
    final costDatasource = CostRemoteDatasource(supabase: supabase);
    final costRepo = CostRepoImpl(datasource: costDatasource);
    final getCosts = GetCosts(costRepo);
    final addCost = AddCost(costRepo);
    final updateCost = UpdateCost(costRepo);
    final deleteCost = DeleteCost(costRepo);
    final getCostCategories = GetCostCategories(costRepo);
    final createCostCategory = CreateCostCategory(costRepo);
    final categoryEmojiRemoteDatasource = CategoryEmojiRemoteDatasourceImpl(
      supabase: supabase,
    );
    final categoryEmojiLocalDatasource = CategoryEmojiLocalDatasourceImpl();
    final categoryEmojiRepo = CategoryEmojiRepoImpl(
      remoteDatasource: categoryEmojiRemoteDatasource,
      localDatasource: categoryEmojiLocalDatasource,
    );
    final getCategoryEmojis = GetCategoryEmojis(categoryEmojiRepo);

    // House
    final houseDatasource = HouseRemoteDatasource(supabase: supabase);
    final houseRepo = HouseRepoImpl(datasource: houseDatasource);
    final createHouse = CreateHouse(houseRepo);
    final getMyHouses = GetMyHouses(houseRepo);
    final getHouseDetail = GetHouseDetail(houseRepo);
    final getHouseMembers = GetHouseMembers(houseRepo);
    final getHouseInvite = GetHouseInvite(houseRepo);
    final regenerateInviteCode = RegenerateInviteCode(houseRepo);
    final joinHouse = JoinHouse(houseRepo);
    final leaveHouse = LeaveHouse(houseRepo);
    final removeMember = RemoveMember(houseRepo);
    final getSprints = GetSprints(houseRepo);
    final createSprint = CreateSprint(houseRepo);
    final closeSprint = CloseSprint(houseRepo);
    final getSprintStats = GetSprintStats(houseRepo);

    // Meal
    final mealDatasource = MealRemoteDatasource(supabase: supabase);
    final mealRepo = MealRepoImpl(datasource: mealDatasource);
    final getMealLogs = GetMealLogs(mealRepo);
    final upsertMealLog = UpsertMealLog(mealRepo);

    // Settlement
    final settlementDatasource = SettlementRemoteDatasource(supabase: supabase);
    final settlementRepo = SettlementRepoImpl(datasource: settlementDatasource);
    final computeSettlement = ComputeSettlement(settlementRepo);
    final getCycleSettlement = GetCycleSettlement(settlementRepo);

    // Dashboard
    final dashboardDatasource = DashboardRemoteDatasource(supabase: supabase);
    final dashboardRepo = DashboardRepoImpl(datasource: dashboardDatasource);
    final getDashboardSummary = GetDashboardSummary(dashboardRepo);

    // Blocs
    final authGuardBloc = AppAuthGuardBloc(watchAuthStatus: watchAuthStatus)
      ..add(const AppAuthGuardStarted());
    final appThemeCubit = AppThemeCubit();
    final houseContextCubit = HouseContextCubit(getMyHouses: getMyHouses);

    return AppDependencies._(
      supabase: supabase,
      authDatasource: authDatasource,
      authRepo: authRepo,
      watchAuthStatus: watchAuthStatus,
      signInWithEmail: signInWithEmail,
      signUpWithEmail: signUpWithEmail,
      logout: logout,
      getCurrentAccount: getCurrentAccount,
      deleteAccount: deleteAccount,
      resendEmailVerification: resendEmailVerification,
      sendPasswordResetEmail: sendPasswordResetEmail,
      verifyPasswordResetOtp: verifyPasswordResetOtp,
      resetPassword: resetPassword,
      costDatasource: costDatasource,
      costRepo: costRepo,
      getCosts: getCosts,
      addCost: addCost,
      updateCost: updateCost,
      deleteCost: deleteCost,
      getCostCategories: getCostCategories,
      createCostCategory: createCostCategory,
      categoryEmojiRemoteDatasource: categoryEmojiRemoteDatasource,
      categoryEmojiLocalDatasource: categoryEmojiLocalDatasource,
      categoryEmojiRepo: categoryEmojiRepo,
      getCategoryEmojis: getCategoryEmojis,
      houseDatasource: houseDatasource,
      houseRepo: houseRepo,
      createHouse: createHouse,
      getMyHouses: getMyHouses,
      getHouseDetail: getHouseDetail,
      getHouseMembers: getHouseMembers,
      getHouseInvite: getHouseInvite,
      regenerateInviteCode: regenerateInviteCode,
      joinHouse: joinHouse,
      leaveHouse: leaveHouse,
      removeMember: removeMember,
      getSprints: getSprints,
      createSprint: createSprint,
      closeSprint: closeSprint,
      getSprintStats: getSprintStats,
      mealDatasource: mealDatasource,
      mealRepo: mealRepo,
      getMealLogs: getMealLogs,
      upsertMealLog: upsertMealLog,
      settlementDatasource: settlementDatasource,
      settlementRepo: settlementRepo,
      computeSettlement: computeSettlement,
      getCycleSettlement: getCycleSettlement,
      dashboardDatasource: dashboardDatasource,
      dashboardRepo: dashboardRepo,
      getDashboardSummary: getDashboardSummary,
      authGuardBloc: authGuardBloc,
      appThemeCubit: appThemeCubit,
      houseContextCubit: houseContextCubit,
    );
  }

  Future<void> dispose() async {
    await authGuardBloc.close();
    await appThemeCubit.close();
    await houseContextCubit.close();
  }
}

class AppDependencyScope extends StatelessWidget {
  const AppDependencyScope({
    super.key,
    required this.dependencies,
    required this.child,
  });

  final AppDependencies dependencies;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDependencies>.value(value: dependencies),
        RepositoryProvider<SupabaseClient>.value(value: dependencies.supabase),

        // Auth
        RepositoryProvider<AuthRepo>.value(value: dependencies.authRepo),
        RepositoryProvider<WatchAuthStatus>.value(
          value: dependencies.watchAuthStatus,
        ),
        RepositoryProvider<SignInWithEmail>.value(
          value: dependencies.signInWithEmail,
        ),
        RepositoryProvider<SignUpWithEmail>.value(
          value: dependencies.signUpWithEmail,
        ),
        RepositoryProvider<Logout>.value(value: dependencies.logout),
        RepositoryProvider<GetCurrentAccount>.value(
          value: dependencies.getCurrentAccount,
        ),
        RepositoryProvider<DeleteAccount>.value(
          value: dependencies.deleteAccount,
        ),
        RepositoryProvider<ResendEmailVerification>.value(
          value: dependencies.resendEmailVerification,
        ),
        RepositoryProvider<SendPasswordResetEmail>.value(
          value: dependencies.sendPasswordResetEmail,
        ),
        RepositoryProvider<VerifyPasswordResetOtp>.value(
          value: dependencies.verifyPasswordResetOtp,
        ),
        RepositoryProvider<ResetPassword>.value(
          value: dependencies.resetPassword,
        ),

        // Cost
        RepositoryProvider<CostRepo>.value(value: dependencies.costRepo),
        RepositoryProvider<GetCosts>.value(value: dependencies.getCosts),
        RepositoryProvider<AddCost>.value(value: dependencies.addCost),
        RepositoryProvider<UpdateCost>.value(value: dependencies.updateCost),
        RepositoryProvider<DeleteCost>.value(value: dependencies.deleteCost),
        RepositoryProvider<GetCostCategories>.value(
          value: dependencies.getCostCategories,
        ),
        RepositoryProvider<CreateCostCategory>.value(
          value: dependencies.createCostCategory,
        ),
        RepositoryProvider<CategoryEmojiRepo>.value(
          value: dependencies.categoryEmojiRepo,
        ),
        RepositoryProvider<GetCategoryEmojis>.value(
          value: dependencies.getCategoryEmojis,
        ),

        // House
        RepositoryProvider<HouseRepo>.value(value: dependencies.houseRepo),
        RepositoryProvider<CreateHouse>.value(value: dependencies.createHouse),
        RepositoryProvider<GetMyHouses>.value(value: dependencies.getMyHouses),
        RepositoryProvider<GetHouseDetail>.value(
          value: dependencies.getHouseDetail,
        ),
        RepositoryProvider<GetHouseMembers>.value(
          value: dependencies.getHouseMembers,
        ),
        RepositoryProvider<GetHouseInvite>.value(
          value: dependencies.getHouseInvite,
        ),
        RepositoryProvider<RegenerateInviteCode>.value(
          value: dependencies.regenerateInviteCode,
        ),
        RepositoryProvider<JoinHouse>.value(value: dependencies.joinHouse),
        RepositoryProvider<LeaveHouse>.value(value: dependencies.leaveHouse),
        RepositoryProvider<RemoveMember>.value(
          value: dependencies.removeMember,
        ),
        RepositoryProvider<GetSprints>.value(value: dependencies.getSprints),
        RepositoryProvider<CreateSprint>.value(
          value: dependencies.createSprint,
        ),
        RepositoryProvider<CloseSprint>.value(value: dependencies.closeSprint),
        RepositoryProvider<GetSprintStats>.value(
          value: dependencies.getSprintStats,
        ),

        // Meal
        RepositoryProvider<MealRepo>.value(value: dependencies.mealRepo),
        RepositoryProvider<GetMealLogs>.value(value: dependencies.getMealLogs),
        RepositoryProvider<UpsertMealLog>.value(
          value: dependencies.upsertMealLog,
        ),

        // Settlement
        RepositoryProvider<SettlementRepo>.value(
          value: dependencies.settlementRepo,
        ),
        RepositoryProvider<ComputeSettlement>.value(
          value: dependencies.computeSettlement,
        ),
        RepositoryProvider<GetCycleSettlement>.value(
          value: dependencies.getCycleSettlement,
        ),

        // Dashboard
        RepositoryProvider<DashboardRepo>.value(
          value: dependencies.dashboardRepo,
        ),
        RepositoryProvider<GetDashboardSummary>.value(
          value: dependencies.getDashboardSummary,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AppThemeCubit>.value(value: dependencies.appThemeCubit),
          BlocProvider<AppAuthGuardBloc>.value(
            value: dependencies.authGuardBloc,
          ),
          BlocProvider<HouseContextCubit>.value(
            value: dependencies.houseContextCubit,
          ),
        ],
        child: child,
      ),
    );
  }
}
