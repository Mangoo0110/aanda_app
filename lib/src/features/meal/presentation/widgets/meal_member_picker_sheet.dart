import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/meal/presentation/bloc/house_meals/house_meals_bloc.dart';

class MealMemberPickerSheet extends StatelessWidget {
  const MealMemberPickerSheet({
    super.key,
    required this.members,
    required this.currentSelected,
    required this.state,
    required this.onSelectMember,
  });

  final List<HouseMember> members;
  final HouseMember currentSelected;
  final HouseMealsState state;
  final ValueChanged<String> onSelectMember;

  static const Color darkText = Color(0xFF1B1D1F);
  static const Color subText = Color(0xFF8C8D8E);
  static const Color primaryCoral = Color(0xFFD85A38);
  static const Color cardColor = Colors.white;

  static void show({
    required BuildContext context,
    required List<HouseMember> members,
    required HouseMember currentSelected,
    required HouseMealsState state,
    required ValueChanged<String> onSelectMember,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => MealMemberPickerSheet(
        members: members,
        currentSelected: currentSelected,
        state: state,
        onSelectMember: onSelectMember,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Select Roommate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: members.length,
                  itemBuilder: (ctx, idx) {
                    final m = members[idx];
                    final isSelected = m.userId == currentSelected.userId;
                    final isYou = m.userId == currentUserId || idx == 0;
                    final total = state.mealLogs
                        .where((log) => log.userId == m.userId)
                        .fold<double>(
                          0.0,
                          (sum, log) => sum + log.totalMeals,
                        );
                    final totalStr = total.toStringAsFixed(
                      total.truncateToDouble() == total ? 0 : 1,
                    );

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? primaryCoral.withValues(alpha: 0.15)
                            : (isYou
                                ? const Color(0xFF1B1D1F)
                                : const Color(0xFFF1F3F5)),
                        child: Text(
                          m.displayName.isNotEmpty
                              ? m.displayName[0].toUpperCase()
                              : 'M',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? primaryCoral
                                : (isYou
                                    ? Colors.white
                                    : const Color(0xFF495057)),
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              m.displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSelected ? primaryCoral : darkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isYou) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
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
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '$totalStr meals logged in cycle',
                        style: const TextStyle(
                          fontSize: 11,
                          color: subText,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: primaryCoral,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        onSelectMember(m.userId);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
