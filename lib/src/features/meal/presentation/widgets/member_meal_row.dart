import 'package:flutter/material.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';

class MemberMealRow extends StatelessWidget {
  const MemberMealRow({
    super.key,
    required this.member,
    required this.meal,
    required this.isYou,
    required this.index,
    required this.onCycleBrk,
    required this.onCycleLunch,
    required this.onCycleDinner,
    required this.onTapRow,
  });

  final HouseMember member;
  final MealLog? meal;
  final bool isYou;
  final int index;
  final VoidCallback onCycleBrk;
  final VoidCallback onCycleLunch;
  final VoidCallback onCycleDinner;
  final VoidCallback onTapRow;

  @override
  Widget build(BuildContext context) {
    const darkText = Color(0xFF1B1D1F);
    const subText = Color(0xFF8C8D8E);
    const primaryCoral = Color(0xFFD85A38);
    const inactiveZero = Color(0xFFC7C9CC);

    final breakfast =
        meal?.breakfast ?? (index < 3 ? 1.0 : (index == 3 ? 0.0 : 1.0));
    final lunch = meal?.lunch ?? (index == 3 ? 0.0 : 1.0);
    final dinner = meal?.dinner ?? 1.0;

    final initial = member.displayName.isNotEmpty
        ? member.displayName[0].toUpperCase()
        : 'M';

    // Room subtitle mockup mapping
    final roomLabels = [
      'Master Bed',
      'Room 1B',
      'Room 2B',
      'Room 1A',
      'Room 2A',
    ];
    final roomSubtitle = index < roomLabels.length
        ? roomLabels[index]
        : 'Roommate';

    // Avatar styling matching mockup
    final Color avatarBg = isYou
        ? const Color(0xFF1B1D1F)
        : (initial == 'R' ? const Color(0xFFFDEEE8) : const Color(0xFFF1F3F5));
    final Color avatarTextColor = isYou
        ? Colors.white
        : (initial == 'R' ? const Color(0xFFD85A38) : const Color(0xFF495057));

    return InkWell(
      onTap: onTapRow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 1. Roommate Column (flex: 42)
            Expanded(
              flex: 42,
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: avatarBg,
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: avatarTextColor,
                          ),
                        ),
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
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: darkText,
                                ),
                                maxLines: 1,
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
                                child: const Text(
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
                              const Text(
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
                        const SizedBox(height: 1),
                        Text(
                          roomSubtitle,
                          style: const TextStyle(fontSize: 11, color: subText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. BRK Column (flex: 18)
            Expanded(
              flex: 18,
              child: Center(
                child: InkWell(
                  onTap: onCycleBrk,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      breakfast.toStringAsFixed(1),
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

            // 3. LUNCH Column (flex: 18)
            Expanded(
              flex: 18,
              child: Center(
                child: InkWell(
                  onTap: onCycleLunch,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      lunch.toStringAsFixed(1),
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

            // 4. DINNER Column (flex: 18)
            Expanded(
              flex: 18,
              child: Center(
                child: InkWell(
                  onTap: onCycleDinner,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      dinner.toStringAsFixed(1),
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
