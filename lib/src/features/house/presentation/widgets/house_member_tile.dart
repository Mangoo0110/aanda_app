import 'package:flutter/material.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/entities/member_role.dart';

class HouseMemberTile extends StatelessWidget {
  const HouseMemberTile({
    super.key,
    required this.member,
    required this.isCurrentUser,
    required this.canRemove,
    required this.onRemove,
  });

  final HouseMember member;
  final bool isCurrentUser;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: colors.primaryColor.withValues(alpha: 0.1),
            child: Text(
              member.displayName.isNotEmpty
                  ? member.displayName[0].toUpperCase()
                  : 'M',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: colors.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colors.textColor,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(You)',
                        style: TextStyle(fontSize: 12, color: colors.grey),
                      ),
                    ],
                  ],
                ),
                Text(
                  member.role == MemberRole.admin ? 'Admin' : 'Member',
                  style: TextStyle(
                    fontSize: 12,
                    color: member.role == MemberRole.admin
                        ? colors.primaryColor
                        : colors.grey,
                    fontWeight: member.role == MemberRole.admin
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (canRemove)
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline_rounded,
                color: colors.errorColor,
                size: 18,
              ),
              tooltip: 'Remove Member',
              onPressed: () => _confirmRemove(context),
            ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    final colors = AppColors.context(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove Member', style: TextStyle(color: colors.textColor)),
        content: Text(
          'Are you sure you want to remove ${member.displayName} from this house?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.errorColor),
            onPressed: () {
              Navigator.of(ctx).pop();
              onRemove();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
