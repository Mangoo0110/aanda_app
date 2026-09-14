import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Full-page fallback for backend/system failures.
/// Use this instead of silently showing empty seeded data.
class SystemProblemView extends StatelessWidget {
  const SystemProblemView({
    super.key,
    this.title,
    this.message,
    this.actionLabel,
    required this.onRetry,
  });

  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final primary = colors.primaryColor;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_off_rounded, color: primary, size: 42),
              ),
              const SizedBox(height: 22),
              Text(
                (title ?? 'System is having a problem'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF202020),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                (message ??
                    'We could not load this information right now. Please try again in a moment.'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF727272),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text((actionLabel ?? 'Try again')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
