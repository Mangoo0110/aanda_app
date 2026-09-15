import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
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
  late final FocusNode _amountFocusNode;
  bool _showNote = false;
  bool _initializedFromEdit = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _nameController = TextEditingController();
    _noteController = TextEditingController();
    _amountFocusNode = FocusNode();

    // Trigger form started to load categories and houses
    context.read<CostFormBloc>().add(const CostFormStarted());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
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

        if (state.isEditing && !_initializedFromEdit) {
          _initializedFromEdit = true;
          if (state.amount > 0) {
            _amountController.text = state.amount.toStringAsFixed(2);
          }
          _nameController.text = state.name;
          _noteController.text = state.note;
          if (state.note.isNotEmpty) {
            _showNote = true;
          }
        }
      },
      builder: (context, state) {
        final now = DateTime.now();
        final isToday = state.purchaseDate.year == now.year &&
            state.purchaseDate.month == now.month &&
            state.purchaseDate.day == now.day;
        final dateLabel = isToday
            ? 'Today'
            : DateFormat('d MMM').format(state.purchaseDate);

        return Scaffold(
          backgroundColor: colors.appBackgroundColor,
          appBar: AppBar(
            title: Text(
              state.isEditing ? 'Edit Expense' : 'Add Expense',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                // ── Hero Amount Input ───────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '৳',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w700,
                              color: colors.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          IntrinsicWidth(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 70),
                              child: TextField(
                                controller: _amountController,
                                focusNode: _amountFocusNode,
                                autofocus: !state.isEditing,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textColor,
                                  letterSpacing: -1,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    color: colors.grey.withValues(alpha: 0.3),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) {
                                  final amt =
                                      double.tryParse(val.trim()) ?? 0.0;
                                  context
                                      .read<CostFormBloc>()
                                      .add(CostFormAmountChanged(amt));
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Title Input ─────────────────────────────────────────────
                TextField(
                  controller: _nameController,
                  style: TextStyle(
                    color: colors.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'What did you spend on? (e.g. Lunch, Groceries)',
                    hintStyle: TextStyle(
                      color: colors.hintColor,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    filled: true,
                    fillColor: colors.surfaceColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colors.borderColor.withValues(alpha: 0.4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colors.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    context.read<CostFormBloc>().add(CostFormNameChanged(val));
                  },
                ),
                const SizedBox(height: 20),

                // ── Reference / Charged To (Myself vs Groups) ────────────────
                Text(
                  'Charge to',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Myself (Personal)
                      _ReferenceChip(
                        label: 'Myself',
                        icon: Icons.person_rounded,
                        isSelected: state.costScope == CostScope.personal,
                        onTap: () {
                          context.read<CostFormBloc>().add(
                            const CostFormReferenceChanged(
                              scope: CostScope.personal,
                              houseId: null,
                            ),
                          );
                        },
                      ),
                      // Shared Groups / Houses
                      ...state.availableHouses.map((house) {
                        final isSelected = state.costScope == CostScope.shared &&
                            state.selectedHouseId == house.id;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _ReferenceChip(
                            label: house.name,
                            icon: Icons.home_work_rounded,
                            isSelected: isSelected,
                            onTap: () {
                              context.read<CostFormBloc>().add(
                                CostFormReferenceChanged(
                                  scope: CostScope.shared,
                                  houseId: house.id,
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Category Selector ───────────────────────────────────────
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.availableCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final cat = state.availableCategories[idx];
                      final isSelected = state.selectedCategory?.id == cat.id;
                      return ChoiceChip(
                        selected: isSelected,
                        avatar: Icon(
                          _iconForCategory(cat.icon),
                          size: 14,
                          color: isSelected ? Colors.white : colors.iconColor,
                        ),
                        label: Text(cat.name),
                        labelStyle: TextStyle(
                          fontSize: 12,
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
                                : colors.borderColor.withValues(alpha: 0.4),
                          ),
                        ),
                        onSelected: (selected) {
                          context.read<CostFormBloc>().add(
                            CostFormCategoryChanged(selected ? cat : null),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // ── Date & Quick Note Toggle ────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date picker pill
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: state.purchaseDate,
                          firstDate: DateTime(2020),
                          lastDate:
                              DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null && context.mounted) {
                          context
                              .read<CostFormBloc>()
                              .add(CostFormDateChanged(picked));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colors.borderColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: colors.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dateLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Toggle note button
                    if (!_showNote)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showNote = true;
                          });
                        },
                        icon: Icon(
                          Icons.note_add_outlined,
                          size: 15,
                          color: colors.grey,
                        ),
                        label: Text(
                          'Add Note',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),

                if (_showNote) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    style: TextStyle(color: colors.textColor, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Optional memo...',
                      hintStyle:
                          TextStyle(color: colors.hintColor, fontSize: 13),
                      filled: true,
                      fillColor: colors.surfaceColor,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colors.borderColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      context
                          .read<CostFormBloc>()
                          .add(CostFormNoteChanged(val));
                    },
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReferenceChip extends StatelessWidget {
  const _ReferenceChip({
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
    final colors = AppColors.context(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryColor : colors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colors.primaryColor
                : colors.borderColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : colors.iconColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : colors.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
