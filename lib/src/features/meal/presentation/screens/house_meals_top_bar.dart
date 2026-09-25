part of 'house_meals_screen.dart';

class _HouseMealsTopBar extends StatelessWidget {
  const _HouseMealsTopBar({
    required this.houseName,
    required this.memberCount,
    required this.viewMode,
    required this.onViewModeChanged,
    this.showBackButton = true,
  });

  final String houseName;
  final int memberCount;
  final MealViewMode viewMode;
  final ValueChanged<MealViewMode> onViewModeChanged;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showBackButton) ...[
              const AppBackButton(margin: EdgeInsets.zero),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Meals',
                    style: AppTextStyles.pageTitle.copyWith(
                      color: colors.textColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          houseName,
                          style: AppTextStyles.caption.copyWith(
                            color: colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: colors.grey.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                        style: AppTextStyles.caption.copyWith(
                          color: colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // View mode toggle in the app bar right corner
            _ViewModeToggleChip(
              viewMode: viewMode,
              onViewModeChanged: onViewModeChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact pill toggle for Daily / Member shown in the top bar.
class _ViewModeToggleChip extends StatelessWidget {
  const _ViewModeToggleChip({
    required this.viewMode,
    required this.onViewModeChanged,
  });

  final MealViewMode viewMode;
  final ValueChanged<MealViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final isDaily = viewMode == MealViewMode.daily;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChipButton(
            label: 'Daily',
            icon: Icons.calendar_view_day_rounded,
            isSelected: isDaily,
            onTap: () => onViewModeChanged(MealViewMode.daily),
          ),
          _ToggleChipButton(
            label: 'Member',
            icon: Icons.person_rounded,
            isSelected: !isDaily,
            onTap: () => onViewModeChanged(MealViewMode.member),
          ),
        ],
      ),
    );
  }
}

class _ToggleChipButton extends StatelessWidget {
  const _ToggleChipButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF141414) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : const Color(0xFF8C8D8E),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF8C8D8E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
