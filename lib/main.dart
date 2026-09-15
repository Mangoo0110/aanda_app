import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/app/bloc/app_theme_cubit.dart';
import 'package:aanda/src/app/bloc/auth_guard/app_auth_guard_bloc.dart';
import 'package:aanda/src/app/routing/app_router.dart';
import 'package:aanda/src/core/config/supabase_config.dart';
import 'package:aanda/src/core/theme/app_theme.dart';
import 'package:aanda/src/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:aanda/src/features/auth/data/repo/auth_repo_impl.dart';
import 'package:aanda/src/features/auth/domain/repo/auth_repo.dart';
import 'package:aanda/src/features/auth/domain/usecases/auth_usecases.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    // ignore: deprecated_member_use
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const AandaApp());
}

class AandaApp extends StatelessWidget {
  const AandaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    // ── Data layer ────────────────────────────────────────────────────────
    final authDatasource = SupabaseAuthDatasource(supabase: supabase);
    final authRepo = AuthRepoImpl(datasource: authDatasource);

    // ── Use cases ─────────────────────────────────────────────────────────
    final watchAuthStatus = WatchAuthStatus(authRepo);
    final signInWithEmail = SignInWithEmail(authRepo);
    final signUpWithEmail = SignUpWithEmail(authRepo);
    final logout = Logout(authRepo);
    final getCurrentAccount = GetCurrentAccount(authRepo);

    // ── Auth guard bloc ───────────────────────────────────────────────────
    final authGuardBloc = AppAuthGuardBloc(watchAuthStatus: watchAuthStatus)
      ..add(const AppAuthGuardStarted());

    return MultiRepositoryProvider(
      providers: [
        // Repos
        RepositoryProvider<AuthRepo>.value(value: authRepo),
        RepositoryProvider<SupabaseClient>.value(value: supabase),
        // Use cases — exposed so router shell BlocProviders can read them
        RepositoryProvider<SignInWithEmail>.value(value: signInWithEmail),
        RepositoryProvider<SignUpWithEmail>.value(value: signUpWithEmail),
        RepositoryProvider<Logout>.value(value: logout),
        RepositoryProvider<GetCurrentAccount>.value(value: getCurrentAccount),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AppThemeCubit>(create: (_) => AppThemeCubit()),
          BlocProvider<AppAuthGuardBloc>.value(value: authGuardBloc),
        ],
        child: _AppRoot(authGuardBloc: authGuardBloc),
      ),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot({required this.authGuardBloc});

  final AppAuthGuardBloc authGuardBloc;

  @override
  Widget build(BuildContext context) {
    final router = createAppRouter(authGuardBloc: authGuardBloc);
    final appTheme = AppTheme();

    return BlocBuilder<AppThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp.router(
          title: 'Aanda',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: appTheme.lightTheme,
          darkTheme: appTheme.darkTheme,
          routerConfig: router,
        );
      },
    );
  }
}
