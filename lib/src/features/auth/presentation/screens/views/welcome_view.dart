import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/constants/assets.dart';
import 'package:aanda/src/core/theme/app_colors.dart';

/// Welcome landing screen for Track Banana.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 32
                      ? constraints.maxHeight - 32
                      : 0,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // ── 1. Top Logo (Mascot + Brand together) ──
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          Assets.appLogoAndName,
                          height: 52,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── 2. Greeting Headline ──
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Welcome to\nTrack Banana ',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: colors.textColor,
                                height: 1.18,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const TextSpan(
                              text: '👋',
                              style: TextStyle(fontSize: 28),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── 3. Value Proposition Copy ──
                      Text(
                        'Keep track of your daily personal spending effortlessly, or team up with roommates to manage shared costs, log everyday meals, and settle monthly balances without the headache.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                          color: colors.textColor.withValues(alpha: 0.82),
                          letterSpacing: -0.1,
                        ),
                      ),

                      const Spacer(),

                      const SizedBox(height: 24),

                      // ── 4. Action Buttons ──
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: () => context.go(AppRoutes.authRegister),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          child: const Text('Create an account'),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: () => context.go(AppRoutes.authLogin),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.softGrey,
                            foregroundColor: colors.textColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          child: const Text('Log in'),
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
