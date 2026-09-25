import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/presentation/widgets/category_icon_view.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'amount_text.dart';

class CostListRow extends StatelessWidget {
  const CostListRow({
    super.key,
    required this.cost,
    this.currentUserId,
    this.showDate = false,
    required this.onTap,
  });

  final Cost cost;
  final String? currentUserId;
  final bool showDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final String timeStr;
    if (showDate) {
      final now = DateTime.now();
      final isToday = cost.purchaseDate.year == now.year &&
          cost.purchaseDate.month == now.month &&
          cost.purchaseDate.day == now.day;
      timeStr = isToday
          ? DateFormat('h:mm a').format(cost.purchaseDate)
          : DateFormat('d MMM, h:mm a').format(cost.purchaseDate);
    } else {
      timeStr = DateFormat('h:mm a').format(cost.purchaseDate);
    }

    // Build subtitle: payer (if not current user), note or category
    final isYou = cost.paidBy == currentUserId;
    final payerText = cost.isShared
        ? (isYou ? 'You' : (cost.payerName ?? 'Member'))
        : null;

    final List<String> details = [];
    if (payerText != null) details.add(payerText);
    details.add(timeStr);
    if (cost.note != null && cost.note!.trim().isNotEmpty) {
      details.add(cost.note!.trim());
    }

    final subtitle = details.join(' · ');

    // Tag resolution
    final (tagText, tagBg, tagColor) = _resolveTag(cost, colors);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Category Icon (clean 40x40 circle/squircle)
              CategoryIconView(
                icon: cost.categoryIcon,
                categoryName: cost.categoryName,
                size: 40,
                borderRadius: 12,
              ),
              const SizedBox(width: 12),

              // 2. Title & subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cost.name,
                      style: AppTextStyles.rowTitle.copyWith(
                        color: colors.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTextStyles.rowSubtitle.copyWith(
                        color: colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 3. Amount & Status Pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AmountText(
                    amount: cost.amount,
                    style: AppTextStyles.amountSmall.copyWith(
                      color: colors.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tagBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tagText,
                      style: AppTextStyles.badge.copyWith(
                        color: tagColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color, Color) _resolveTag(Cost cost, AppColors colors) {
    if (cost.isPersonal) {
      return ('Personal', colors.softGrey, colors.grey);
    }
    if (cost.isSettled) {
      return ('Settled', colors.positiveColor.withValues(alpha: 0.12), colors.positiveColor);
    }
    final cat = (cost.categoryName ?? '').toLowerCase();
    if (cat.contains('meal') || cat.contains('food') || cat.contains('bazar')) {
      return ('Meal Pool', colors.primaryColor.withValues(alpha: 0.12), colors.primaryColor);
    }
    return ('Shared', colors.warningColor.withValues(alpha: 0.14), colors.warningColor);
  }
}
