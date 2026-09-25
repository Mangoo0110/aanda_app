import 'package:flutter/material.dart';
import 'package:aanda/src/core/theme/app_colors.dart';

class ErrorNotice extends StatelessWidget {
  const ErrorNotice(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorColor.withAlpha(28),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: colors.errorColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 8,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.errorColor,
                  height: 1.3,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
