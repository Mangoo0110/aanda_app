import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aanda/src/app/bloc/auth_guard/app_auth_guard_bloc.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/constants/assets.dart';
import 'package:aanda/src/core/error_handler/friendly_error.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/auth/domain/entities/auth_status.dart';
import 'package:aanda/src/features/profile/presentation/cubit/profile_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  FriendlyError? _error;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    setState(() {
      _error = null;
    });

    final stopwatch = Stopwatch()..start();

    try {
      // 1. Check Auth state
      final authGuardBloc = context.read<AppAuthGuardBloc>();
      final profileCubit = context.read<ProfileCubit>();
      final houseContextCubit = context.read<HouseContextCubit>();

      // If auth is still determining initial signature, wait briefly for it
      if (authGuardBloc.state is LoadingAuthSignature) {
        await authGuardBloc.stream
            .firstWhere((state) => state is! LoadingAuthSignature)
            .timeout(const Duration(seconds: 8));
      }

      final authState = authGuardBloc.state;
      final session = Supabase.instance.client.auth.currentSession;

      // If user is unauthenticated or has no session, direct to auth welcome
      if (authState is UnAuthenticated || session == null) {
        await _ensureMinDisplay(stopwatch, minMs: 1100);
        if (!mounted) return;
        context.go(AppRoutes.auth);
        return;
      }

      final userId = session.user.id;

      // 2. Load Profile and House Context concurrently
      final profileFuture = profileCubit.loadProfile(userId);
      final houseFuture = houseContextCubit.load();

      await Future.wait([profileFuture, houseFuture])
          .timeout(const Duration(seconds: 12));

      // 3. Inspect results for errors
      final profileState = profileCubit.state;
      if (profileState.status == ProfileStatus.failure) {
        if (!mounted) return;
        setState(() {
          _error = FriendlyError.from(profileState.errorMessage);
        });
        return;
      }

      final houseState = houseContextCubit.state;
      if (houseState.status == HouseContextStatus.failure) {
        if (!mounted) return;
        setState(() {
          _error = FriendlyError.from(houseState.errorMessage);
        });
        return;
      }

      await _ensureMinDisplay(stopwatch, minMs: 1100);
      if (!mounted) return;

      // 4. Decide destination based on profile completeness
      final profile = profileState.profile;
      if (profile == null || !profile.isComplete) {
        context.go(AppRoutes.profileOnboarding);
      } else {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = FriendlyError.from(e);
      });
    }
  }

  Future<void> _ensureMinDisplay(Stopwatch stopwatch, {required int minMs}) async {
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < minMs) {
      await Future.delayed(Duration(milliseconds: minMs - elapsed));
    }
  }

  void _onRetry() {
    _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _error != null
              ? _buildErrorView(colors)
              : _buildLoadingView(colors),
        ),
      ),
    );
  }

  Widget _buildLoadingView(AppColors colors) {
    return Center(
      key: const ValueKey('loading_view'),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Inside logo illustration
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: colors.softGrey,
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  Assets.appLogoForInside,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              // App name logo
              Image.asset(
                Assets.appNameLogo,
                height: 38,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 48),
              // Sleek, borderless loading indicator
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(AppColors colors) {
    final error = _error!;

    return Center(
      key: const ValueKey('error_view'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Friendly visual indicator
            if (error.isNetwork) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  Assets.offlineCloud,
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
            ] else ...[
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colors.softGrey,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sentiment_dissatisfied_rounded,
                  size: 54,
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 28),

            // Friendly Title
            Text(
              error.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),

            // Friendly Message
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 36),

            // Premium Borderless "Try Again" Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _onRetry,
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primaryColor.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Try Again',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
