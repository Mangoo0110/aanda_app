import 'package:flutter/material.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/utils/helpers/avatar_image_provider.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';

class MemberMealRow extends StatelessWidget {
  const MemberMealRow({
    super.key,
    required this.member,
    required this.meal,
    required this.isYou,
    required this.index,
    this.onCycleBrk,
    this.onCycleLunch,
    this.onCycleDinner,
    this.onTapRow,
    this.flexMember = 42,
    this.flexBrk = 18,
    this.flexLunch = 18,
    this.flexDinner = 18,
    this.useMockFallback = false,
  });

  final HouseMember member;
  final MealLog? meal;
  final bool isYou;
  final int index;
  final VoidCallback? onCycleBrk;
  final VoidCallback? onCycleLunch;
  final VoidCallback? onCycleDinner;
  final VoidCallback? onTapRow;
  final int flexMember;
  final int flexBrk;
  final int flexLunch;
  final int flexDinner;
  final bool useMockFallback;

  String _formatCount(double count) {
    if (count == 0) return '0';
    return count % 1 == 0 ? count.toInt().toString() : count.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final darkText = colors.textPrimaryColor;
    final subText = colors.textSecondaryColor;
    final primaryCoral = colors.primaryColor;
    const inactiveZero = Color(0xFFC7C9CC);

    final breakfast = meal?.breakfast ??
        (useMockFallback ? (index < 3 ? 1.0 : (index == 3 ? 0.0 : 1.0)) : 0.0);
    final lunch = meal?.lunch ??
        (useMockFallback ? (index == 3 ? 0.0 : 1.0) : 0.0);
    final dinner = meal?.dinner ??
        (useMockFallback ? 1.0 : 0.0);

    final initial = member.displayName.isNotEmpty
        ? member.displayName[0].toUpperCase()
        : 'M';
    final avatarProvider = getAvatarImageProvider(member.avatarUrl);

    // Avatar styling matching mockup
    final Color avatarBg = isYou
        ? darkText
        : (initial == 'R' ? colors.tileColor : const Color(0xFFF1F3F5));
    final Color avatarTextColor = isYou
        ? Colors.white
        : (initial == 'R' ? primaryCoral : const Color(0xFF495057));

    return InkWell(
      onTap: onTapRow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 1. Roommate Column
            Expanded(
              flex: flexMember,
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: avatarBg,
                        backgroundImage: avatarProvider,
                        child: avatarProvider == null
                            ? Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: avatarTextColor,
                                ),
                              )
                            : null,
                      ),
                      if (isYou)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: darkText,
                                  height: 1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isYou) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryCoral.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'You',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: primaryCoral,
                                  ),
                                ),
                              ),
                            ] else if (member.isAdmin) ...[
                              const SizedBox(width: 4),
                              Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: subText,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. BRK Column
            Expanded(
              flex: flexBrk,
              child: Center(
                child: InkWell(
                  onTap: onCycleBrk ?? onTapRow,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: Text(
                      _formatCount(breakfast),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: breakfast > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: breakfast > 0 ? darkText : inactiveZero,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3. LUNCH Column
            Expanded(
              flex: flexLunch,
              child: Center(
                child: InkWell(
                  onTap: onCycleLunch ?? onTapRow,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: Text(
                      _formatCount(lunch),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: lunch > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: lunch > 0 ? darkText : inactiveZero,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 4. DINNER Column
            Expanded(
              flex: flexDinner,
              child: Center(
                child: InkWell(
                  onTap: onCycleDinner ?? onTapRow,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: Text(
                      _formatCount(dinner),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: dinner > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: dinner > 0 ? darkText : inactiveZero,
                      ),
                    ),
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
