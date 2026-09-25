import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../cost/presentation/widgets/category_icon_view.dart';

class CategoryPill extends StatelessWidget {
  const CategoryPill({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final String? icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CategoryIconView(
                icon: icon,
                categoryName: title,
                size: 28,
                borderRadius: 8,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.rowTitle.copyWith(
                  color: colors.textColor,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.add_rounded,
                size: 16,
                color: colors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    this.icon,
    required this.title,
    this.badge,
    this.amount,
    this.subtitle,
    required this.onAdd,
    this.onTap,
  });

  final String? icon;
  final String title;
  final String? badge;
  final String? amount;
  final String? subtitle;
  final VoidCallback onAdd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return InkWell(
      onTap: onTap ?? onAdd,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CategoryIconView(
              icon: icon,
              categoryName: title,
              size: 36,
              borderRadius: 10,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.rowTitle.copyWith(
                      color: colors.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.rowSubtitle.copyWith(
                        color: colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: colors.primaryColor,
                size: 22,
              ),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}
