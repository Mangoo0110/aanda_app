import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aanda/src/core/shared/widget/app_back_button.dart';
import 'package:aanda/src/core/shared/widget/app_card.dart';
import 'package:aanda/src/core/shared/widget/empty_state_view.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/theme/app_theme.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/usecases/cost_usecases.dart';
import 'package:aanda/src/features/cost/presentation/screens/cost_category_form_screen.dart';
import 'package:aanda/src/features/cost/presentation/widgets/category_icon_view.dart';

class CostCategoriesScreen extends StatefulWidget {
  const CostCategoriesScreen({
    super.key,
    required this.accountId,
    required this.accountName,
    this.isPersonal = false,
  });

  final String accountId;
  final String accountName;
  final bool isPersonal;

  @override
  State<CostCategoriesScreen> createState() => _CostCategoriesScreenState();
}

class _CostCategoriesScreenState extends State<CostCategoriesScreen> {
  List<CostCategory> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final getCostCategories = context.read<GetCostCategories>();
      final res = await getCostCategories(
        GetCostCategoriesParams(houseId: widget.accountId),
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (res.success && res.data != null) {
          _categories = res.data!;
        } else {
          _categories = [];
          _errorMessage = res.message.isNotEmpty ? res.message : 'Failed to load categories';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _openCreateCategory() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await Navigator.of(context).push<CostCategory>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CostCategoryFormScreen(
          initialHouseId: widget.accountId,
          initialHouseName: widget.accountName,
        ),
      ),
    );

    if (result != null && mounted) {
      _loadCategories();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Category "${result.name}" created!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmDeleteCategory(CostCategory category) async {
    final colors = AppColors.context(context);
    final messenger = ScaffoldMessenger.of(context);
    final deleteCostCategory = context.read<DeleteCostCategory>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete Category?',
          style: AppTextStyles.rowTitle.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"? '
          'Existing expenses will preserve their records, but this category will no longer be selectable.',
          style: AppTextStyles.rowSubtitle.copyWith(
            color: colors.grey,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text('Cancel', style: TextStyle(color: colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.unsettledColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final res = await deleteCostCategory(
        DeleteCostCategoryParams(categoryId: category.id),
      );
      if (!mounted) return;
      if (res.success) {
        _loadCategories();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Category "${category.name}" deleted.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(res.message.isNotEmpty ? res.message : 'Failed to delete category'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Category Presets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Category',
            onPressed: _openCreateCategory,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateCategory,
        backgroundColor: colors.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Category'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCategories,
          color: colors.primaryColor,
          child: _buildBody(colors),
        ),
      ),
    );
  }

  Widget _buildBody(AppColors colors) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: colors.primaryColor,
        ),
      );
    }

    if (_errorMessage != null && _categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: colors.grey),
              const SizedBox(height: 12),
              Text(
                'Could not load categories',
                style: AppTextStyles.rowTitle.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.rowSubtitle.copyWith(color: colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCategories,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        // ── Account Info Header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.isPersonal
                          ? Icons.person_rounded
                          : Icons.home_work_rounded,
                      color: colors.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.accountName,
                          style: AppTextStyles.rowTitle.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_categories.length} ${_categories.length == 1 ? "category" : "categories"} configured',
                          style: AppTextStyles.rowSubtitle.copyWith(
                            color: colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Empty State or Category List ──
        if (_categories.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateView(
              icon: Icons.category_outlined,
              title: 'No Custom Categories',
              subtitle:
                  'Custom categories created for ${widget.accountName} will appear here.',
              action: ElevatedButton.icon(
                onPressed: _openCreateCategory,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add First Category'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            sliver: SliverToBoxAdapter(
              child: AppCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: colors.dividerColor,
                  ),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isFixed = cat.costNature == 'fixed';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          CategoryIconView(
                            icon: cat.icon,
                            categoryName: cat.name,
                            size: 40,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.name,
                                  style: AppTextStyles.rowTitle.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.textColor,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (isFixed
                                                ? Colors.blue
                                                : Colors.purple)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isFixed ? 'Fixed' : 'Variable',
                                        style: TextStyle(
                                          color: isFixed
                                              ? Colors.blue.shade700
                                              : Colors.purple.shade700,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (cat.isFood) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          '🍽️ Meal Cost',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: colors.grey,
                            ),
                            tooltip: 'Delete category',
                            onPressed: () => _confirmDeleteCategory(cat),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
