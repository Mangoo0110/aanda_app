import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/theme/app_theme.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';
import 'package:aanda/src/features/meal/presentation/widgets/member_meal_row.dart';

class TodayMealsTableCard extends StatelessWidget {
  const TodayMealsTableCard({
    super.key,
    required this.members,
    required this.mealLogs,
    required this.onOpenMealLog,
    this.currentUserId,
    this.isLoading = false,
  });

  final List<HouseMember> members;
  final List<MealLog> mealLogs;
  final VoidCallback onOpenMealLog;
  final String? currentUserId;
  final bool isLoading;

  static const int _flexMember = 37;
  static const int _flexBrk = 21;
  static const int _flexLunch = 21;
  static const int _flexDinner = 21;

  String? _resolveCurrentUserId() {
    if (currentUserId != null) return currentUserId;
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  MealLog? _logForMember(String userId) {
    return mealLogs.where((l) => l.userId == userId).firstOrNull;
  }

  String _formatCount(double count) {
    if (count == 0) return '0';
    return count % 1 == 0 ? count.toInt().toString() : count.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final todayStr = DateFormat('EEEE, d MMM').format(DateTime.now());
    final effectiveUserId = _resolveCurrentUserId();

    // Totals across all members for today
    double totalBreakfast = 0.0;
    double totalLunch = 0.0;
    double totalDinner = 0.0;

    for (final member in members) {
      final log = _logForMember(member.userId);
      if (log != null) {
        totalBreakfast += log.breakfast;
        totalLunch += log.lunch;
        totalDinner += log.dinner;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.dividerColor.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Card Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.restaurant_rounded,
                          size: 18,
                          color: colors.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Meals",
                          style: AppTextStyles.rowTitle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.textColor,
                          ),
                        ),
                        Text(
                          todayStr,
                          style: AppTextStyles.rowSubtitle.copyWith(
                            fontSize: 11,
                            color: colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                InkWell(
                  onTap: onOpenMealLog,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.softGrey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ledger',
                          style: AppTextStyles.badge.copyWith(
                            color: colors.textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: colors.textColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isLoading)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: colors.primaryColor.withValues(alpha: 0.5),
            ),

          Divider(
            height: 1,
            color: colors.dividerColor.withValues(alpha: 0.5),
          ),

          // ── 2. Table Column Headers with totals in enclosed brackets ─────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: _flexMember,
                  child: Text(
                    'Members',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: _flexBrk,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Breakfast(${_formatCount(totalBreakfast)})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: _flexLunch,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Lunch(${_formatCount(totalLunch)})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: _flexDinner,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Dinner(${_formatCount(totalDinner)})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: colors.dividerColor.withValues(alpha: 0.5),
          ),

          // ── 3. Table Rows (Reusing MemberMealRow) ─────────────────────────
          if (members.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: Text(
                  'No house members found',
                  style: AppTextStyles.rowSubtitle.copyWith(
                    color: colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: members.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: colors.dividerColor.withValues(alpha: 0.4),
              ),
              itemBuilder: (context, index) {
                final member = members[index];
                final meal = _logForMember(member.userId);
                final isYou = (member.userId == effectiveUserId) || index == 0;

                return MemberMealRow(
                  member: member,
                  meal: meal,
                  isYou: isYou,
                  index: index,
                  flexMember: _flexMember,
                  flexBrk: _flexBrk,
                  flexLunch: _flexLunch,
                  flexDinner: _flexDinner,
                  onTapRow: onOpenMealLog,
                );
              },
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
