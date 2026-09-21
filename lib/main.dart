import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aanda/di/app_dependencies.dart';
import 'package:aanda/src/app/bloc/app_theme_cubit.dart';
import 'package:aanda/src/app/bloc/auth_guard/app_auth_guard_bloc.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/app/routing/app_router.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/config/supabase_config.dart';
import 'package:aanda/src/core/network/presentation/network_aware_root.dart';
import 'package:aanda/src/core/theme/app_theme.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/features/auth/domain/entities/auth_status.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DebugService.instance(allowsOnly: DebugLabel.values.toSet());

  await Supabase.initialize(
    url: SupabaseConfig.url,
    // ignore: deprecated_member_use
    anonKey: SupabaseConfig.anonKey,
  );

  final dependencies = AppDependencies.create(
    supabase: Supabase.instance.client,
  );
  final router = createAppRouter(authGuardBloc: dependencies.authGuardBloc);

  // Listen for Supabase password recovery events (magic links or deep links)
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      router.go(AppRoutes.authResetPassword);
    }
  });

  runApp(AandaApp(dependencies: dependencies, router: router));
}

class AandaApp extends StatelessWidget {
  const AandaApp({super.key, required this.dependencies, required this.router});

  final AppDependencies dependencies;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return AppDependencyScope(
      dependencies: dependencies,
      child: _AppRoot(router: router),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppAuthGuardBloc, AuthStatus>(
      listenWhen: (prev, curr) =>
          prev is! Authenticated && curr is Authenticated,
      listener: (context, _) {
        // Load the house list whenever the user signs in.
        context.read<HouseContextCubit>().load();
      },
      child: BlocBuilder<AppThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          final theme = AppTheme();
          return MaterialApp.router(
            title: 'Aanda',
            theme: theme.lightTheme,
            darkTheme: theme.darkTheme,
            themeMode: themeMode,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            builder: (context, child) => NetworkAwareRoot(child: child),
          );
        },
      ),
    );
  }
}
