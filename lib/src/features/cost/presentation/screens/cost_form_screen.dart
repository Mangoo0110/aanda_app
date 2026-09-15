import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_type.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_form/cost_form_bloc.dart';

class CostFormScreen extends StatefulWidget {
  const CostFormScreen({super.key});

  @override
  State<CostFormScreen> createState() => _CostFormScreenState();
}

class _CostFormScreenState extends State<CostFormScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _nameController = TextEditingController();
    _noteController = TextEditingController();

    // Trigger form started to load categories
    context.read<CostFormBloc>().add(const CostFormStarted());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  IconData _iconForCategory(String? iconKey) {
    return switch (iconKey) {
      'restaurant' => Icons.restaurant_rounded,
      'shopping_basket' => Icons.shopping_basket_rounded,
      'directions_bus' => Icons.directions_bus_rounded,
      'flash_on' => Icons.flash_on_rounded,
      'home' => Icons.home_rounded,
      'shopping_bag' => Icons.shopping_bag_rounded,
      'medical_services' => Icons.medical_services_rounded,
      'movie' => Icons.movie_rounded,
      _ => Icons.receipt_long_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return BlocConsumer<CostFormBloc, CostFormState>(
      listener: (context, state) {
        if (state.isSuccess) {
          context.pop(true);
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: colors.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.appBackgroundColor,
          appBar: AppBar(
            title: Text(
              state.isEditing ? 'Edit Expense' : 'Add Expense',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.textColor,
              ),
            ),
            backgroundColor: colors.surfaceColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close_rounded, color: colors.iconColor),
              onPressed: () => context.pop(),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () {
                          context
                              .read<CostFormBloc>()
                              .add(const CostFormSubmitted());
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          state.isEditing ? 'Save Changes' : 'Record Expense',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Scope Selector ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.tileColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ScopeButton(
                          title: 'Personal Expense',
                          icon: Icons.person_rounded,
                          isSelected: state.costScope == CostScope.personal,
                          onTap: () {
                            context.read<CostFormBloc>().add(
                              const CostFormScopeChanged(CostScope.personal),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: _ScopeButton(
                          title: 'Shared (House)',
                          icon: Icons.home_work_rounded,
                          isSelected: state.costScope == CostScope.shared,
                          onTap: () {
                            context.read<CostFormBloc>().add(
                              const CostFormScopeChanged(CostScope.shared),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Amount Hero Input ────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Amount (BDT)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      IntrinsicWidth(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '৳ ',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: colors.primaryColor,
                              ),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 80),
                              child: IntrinsicWidth(
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: colors.textColor,
                                    letterSpacing: -0.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    hintStyle: TextStyle(
                                      color: colors.grey.withValues(alpha: 0.4),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (val) {
                                    final amt = double.tryParse(val.trim()) ?? 0.0;
                                    context
                                        .read<CostFormBloc>()
                                        .add(CostFormAmountChanged(amt));
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Title Input ──────────────────────────────────────────────
                Text(
                  'Description / Title *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: colors.textColor),
                  decoration: InputDecoration(
                    hintText: 'e.g. Weekly Groceries, Lunch with team',
                    hintStyle: TextStyle(color: colors.hintColor),
                    filled: true,
                    fillColor: colors.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colors.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colors.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    context
                        .read<CostFormBloc>()
                        .add(CostFormNameChanged(val));
                  },
                ),
                const SizedBox(height: 20),

                // ── Category Chips ───────────────────────────────────────────
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.availableCategories.map((cat) {
                    final isSelected = state.selectedCategory?.id == cat.id;
                    return ChoiceChip(
                      selected: isSelected,
                      avatar: Icon(
                        _iconForCategory(cat.icon),
                        size: 16,
                        color: isSelected ? Colors.white : colors.iconColor,
                      ),
                      label: Text(cat.name),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : colors.textColor,
                      ),
                      selectedColor: colors.primaryColor,
                      backgroundColor: colors.surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected
                              ? colors.primaryColor
                              : colors.borderColor.withValues(alpha: 0.5),
                        ),
                      ),
                      onSelected: (selected) {
                        context.read<CostFormBloc>().add(
                          CostFormCategoryChanged(selected ? cat : null),
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Date & Cost Type Row ─────────────────────────────────────
                Row(
                  children: [
                    // Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date Spent',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: state.purchaseDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 30),
                                ),
                              );
                              if (picked != null && context.mounted) {
                                context
                                    .read<CostFormBloc>()
                                    .add(CostFormDateChanged(picked));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colors.borderColor.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: colors.iconColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('d MMM, yyyy')
                                        .format(state.purchaseDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Cost Type (Variable vs Fixed)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cost Type',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colors.surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.borderColor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _TypeButton(
                                    title: 'Variable',
                                    isSelected:
                                        state.costType == CostType.variable,
                                    onTap: () {
                                      context.read<CostFormBloc>().add(
                                        const CostFormTypeChanged(
                                          CostType.variable,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: _TypeButton(
                                    title: 'Fixed',
                                    isSelected: state.costType == CostType.fixed,
                                    onTap: () {
                                      context.read<CostFormBloc>().add(
                                        const CostFormTypeChanged(
                                          CostType.fixed,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Note (Optional) ──────────────────────────────────────────
                Text(
                  'Note (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  style: TextStyle(color: colors.textColor),
                  decoration: InputDecoration(
                    hintText: 'Additional details or memo...',
                    hintStyle: TextStyle(color: colors.hintColor),
                    filled: true,
                    fillColor: colors.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colors.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colors.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    context
                        .read<CostFormBloc>()
                        .add(CostFormNoteChanged(val));
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScopeButton extends StatelessWidget {
  const _ScopeButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : colors.unselectedLabelColor,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : colors.unselectedLabelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : colors.textColor,
            ),
          ),
        ),
      ),
    );
  }
}
