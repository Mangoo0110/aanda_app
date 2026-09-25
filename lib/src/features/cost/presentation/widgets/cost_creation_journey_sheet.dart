import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/theme/app_theme.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/domain/usecases/get_cost_categories.dart';
import 'package:aanda/src/features/cost/presentation/screens/cost_category_form_screen.dart';
import 'package:aanda/src/features/cost/presentation/widgets/category_icon_view.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';

/// Guided flow to initiate creating an expense:
/// 1. Select Account (if multiple accounts exist: Personal + Shared Houses).
/// 2. Select Category (loaded for that account, with option to create a new one).
/// 3. Navigates into CostFormScreen with pre-filled account and category.
class CostCreationJourneySheet extends StatefulWidget {
  const CostCreationJourneySheet({
    super.key,
    required this.houses,
    this.preferredHouseId,
    this.initialIsPersonal = false,
  });

  final List<House> houses;
  final String? preferredHouseId;
  final bool initialIsPersonal;

  static Future<bool?> start(
    BuildContext context, {
    String? preferredHouseId,
  }) async {
    final houseCtx = context.read<HouseContextCubit>();
    final houses = houseCtx.state.houses;
    final isPersonal = houseCtx.state.isPersonalView;

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => CostCreationJourneySheet(
        houses: houses,
        preferredHouseId: preferredHouseId ?? (isPersonal ? null : houseCtx.state.selectedHouse?.id),
        initialIsPersonal: isPersonal,
      ),
    );
  }

  @override
  State<CostCreationJourneySheet> createState() =>
      _CostCreationJourneySheetState();
}

class _CostCreationJourneySheetState extends State<CostCreationJourneySheet> {
  int _step = 1; // 1: Account, 2: Category
  String? _selectedHouseId;
  String _selectedHouseName = 'Personal Account';
  CostScope _selectedScope = CostScope.personal;

  List<CostCategory> _categories = CostCategory.predefinedCategories;
  bool _isLoadingCategories = false;

  List<House> get _sharedHouses =>
      widget.houses.where((h) => h.isShared).toList();

  bool get _hasMultipleAccounts => _sharedHouses.isNotEmpty;

  @override
  void initState() {
    super.initState();

    if (!_hasMultipleAccounts) {
      // Only personal account exists -> skip step 1 directly to step 2
      _step = 2;
      _selectedHouseId = null;
      _selectedHouseName = 'Personal Account';
      _selectedScope = CostScope.personal;
      _loadCategories(null);
    } else {
      // Multiple accounts exist: immediately use active account in step 2
      _step = 2;
      if (widget.initialIsPersonal || widget.preferredHouseId == null) {
        _selectedHouseId = null;
        _selectedHouseName = 'Personal Account';
        _selectedScope = CostScope.personal;
      } else {
        final house = _sharedHouses
            .where((h) => h.id == widget.preferredHouseId)
            .firstOrNull;
        if (house != null) {
          _selectedHouseId = house.id;
          _selectedHouseName = house.name;
          _selectedScope = CostScope.shared;
        } else {
          _selectedHouseId = null;
          _selectedHouseName = 'Personal Account';
          _selectedScope = CostScope.personal;
        }
      }
      _loadCategories(_selectedHouseId);
    }
  }

  Future<void> _loadCategories(String? houseId) async {
    setState(() => _isLoadingCategories = true);
    try {
      final getCats = context.read<GetCostCategories>();
      final result = await getCats(GetCostCategoriesParams(houseId: houseId));
      if (result.success && result.data != null && result.data!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _categories = result.data!;
            _isLoadingCategories = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _categories = CostCategory.predefinedCategories;
        _isLoadingCategories = false;
      });
    }
  }

  void _selectAccount({
    required String? houseId,
    required String name,
    required CostScope scope,
  }) {
    if (_selectedHouseId == houseId && _selectedScope == scope) return;
    setState(() {
      _selectedHouseId = houseId;
      _selectedHouseName = name;
      _selectedScope = scope;
    });
    _loadCategories(houseId);
  }

  void _proceedToStep2() {
    setState(() => _step = 2);
    _loadCategories(_selectedHouseId);
  }

  void _onCategorySelected(CostCategory category) async {
    final nav = Navigator.of(context);
    final houseCtx = context.read<HouseContextCubit>();
    nav.pop(true); // Close sheet

    final result = await context.push<bool>(
      AppRoutes.costAdd,
      extra: {
        'category': category,
        'houseId': _selectedHouseId,
        'scope': _selectedScope,
      },
    );
    if (result == true) {
      houseCtx.notifyCostUpdated();
    }
  }

  Future<void> _createNewCategory() async {
    final result = await Navigator.of(context).push<CostCategory>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CostCategoryFormScreen(
          initialHouseId: _selectedHouseId,
          initialHouseName: _selectedHouseName,
        ),
      ),
    );

    if (result != null && mounted) {
      _onCategorySelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
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
            const SizedBox(height: 16),

            // Content based on step
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _step == 1 ? _buildAccountStep(colors) : _buildCategoryStep(colors),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStep(AppColors colors) {
    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.softGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Step 1 of 2',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.grey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Select Account',
          style: AppTextStyles.sectionHeader.copyWith(
            fontSize: 20,
            color: colors.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Where do you want to record this expense?',
          style: AppTextStyles.rowSubtitle.copyWith(color: colors.grey),
        ),
        const SizedBox(height: 16),

        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              // Personal Account Card
              _AccountChoiceTile(
                icon: Icons.person_rounded,
                title: 'Personal Account',
                subtitle: 'Private expense • Only visible to you',
                isSelected: _selectedScope == CostScope.personal,
                colors: colors,
                onTap: () => _selectAccount(
                  houseId: null,
                  name: 'Personal Account',
                  scope: CostScope.personal,
                ),
              ),
              const SizedBox(height: 10),

              // Shared Houses Cards
              ..._sharedHouses.map((house) {
                final isSelected = _selectedScope == CostScope.shared &&
                    _selectedHouseId == house.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AccountChoiceTile(
                    icon: Icons.roofing_rounded,
                    title: house.name,
                    subtitle: '${house.members.length} members • Shared house',
                    isSelected: isSelected,
                    colors: colors,
                    onTap: () => _selectAccount(
                      houseId: house.id,
                      name: house.name,
                      scope: CostScope.shared,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Continue Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: _proceedToStep2,
            style: FilledButton.styleFrom(
              backgroundColor: colors.textColor,
              foregroundColor: colors.invertTextColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryStep(AppColors colors) {
    return Column(
      key: const ValueKey(2),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar: Back (if multiple accounts), Title, + New button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasMultipleAccounts) ...[
                  InkWell(
                    onTap: () => setState(() => _step = 1),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: colors.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  'Select Category',
                  style: AppTextStyles.sectionHeader.copyWith(
                    fontSize: 19,
                    color: colors.textColor,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: _createNewCategory,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.softGrey,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: colors.textColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'New',
                      style: AppTextStyles.badge.copyWith(
                        color: colors.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Account indicator pill (only if multiple accounts exist)
        if (_hasMultipleAccounts) ...[
          InkWell(
            onTap: () => setState(() => _step = 1),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.softGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _selectedScope == CostScope.personal
                          ? colors.grey
                          : colors.textColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedHouseName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 14,
                    color: colors.grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Categories List
        Flexible(
          child: _isLoadingCategories
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                      color: colors.textColor,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 56,
                    color: colors.dividerColor,
                  ),
                  itemBuilder: (ctx, index) {
                    final cat = _categories[index];
                    final isPersonalAccount =
                        _selectedScope == CostScope.personal ||
                        _selectedHouseId == null;
                    final isBlocked = isPersonalAccount && cat.isFood;

                    final tile = ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: CategoryIconView(
                        icon: cat.icon,
                        categoryName: cat.name,
                        size: 38,
                        fallbackEmoji: '🏷️',
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              cat.name,
                              style: AppTextStyles.rowTitle.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.textColor,
                              ),
                            ),
                          ),
                          if (isBlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Shared House Only',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE02424),
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: isBlocked
                          ? Text(
                              'Meal pool is only for shared houses with meal tracking',
                              style: AppTextStyles.rowSubtitle.copyWith(
                                color: const Color(0xFFE02424).withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                            )
                          : ((cat.costNature != 'variable' &&
                                  cat.defaultAmount != null &&
                                  cat.defaultAmount! > 0)
                              ? Text(
                                  'Default: ৳${cat.defaultAmount!.toInt()}',
                                  style: AppTextStyles.rowSubtitle.copyWith(
                                    color: colors.grey,
                                  ),
                                )
                              : null),
                      trailing: isBlocked
                          ? Icon(
                              Icons.block_rounded,
                              size: 18,
                              color: colors.grey,
                            )
                          : Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: colors.grey,
                            ),
                      onTap: isBlocked
                          ? () {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Meal pool category "${cat.name}" cannot be used for personal accounts. Meal pooling is only for shared houses with meal tracking.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFFC81E1E),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          : () => _onCategorySelected(cat),
                    );

                    if (isBlocked) {
                      return Opacity(
                        opacity: 0.42,
                        child: tile,
                      );
                    }
                    return tile;
                  },
                ),
        ),
      ],
    );
  }
}

class _AccountChoiceTile extends StatelessWidget {
  const _AccountChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.softGrey
              : colors.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? colors.textColor
                : colors.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.textColor.withValues(alpha: 0.08)
                    : colors.softGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colors.textColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.rowTitle.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: colors.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.rowSubtitle.copyWith(
                      fontSize: 12,
                      color: colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected
                  ? colors.textColor
                  : colors.grey.withValues(alpha: 0.4),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
