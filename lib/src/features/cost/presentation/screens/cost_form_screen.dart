import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/core/shared/widget/app_back_button.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_form/cost_form_bloc.dart';
import 'package:aanda/src/features/cost/presentation/screens/cost_category_form_screen.dart';
import 'package:aanda/src/features/cost/presentation/widgets/category_icon_view.dart';
import 'package:aanda/src/features/cost/presentation/widgets/cost_account_picker_sheet.dart';
import 'package:aanda/src/features/cost/presentation/widgets/cost_category_picker_sheet.dart';
import 'package:aanda/src/features/cost/presentation/widgets/cost_keypad.dart';
import 'package:aanda/src/features/cost/presentation/widgets/cost_payer_picker_sheet.dart';

class CostFormScreen extends StatefulWidget {
  const CostFormScreen({
    super.key,
    this.initialCost,
    this.initialCategory,
    this.categoryPreset,
    this.initialCategoryId,
    this.initialHouseId,
    this.initialScope,
  });

  final Cost? initialCost;
  final CostCategory? initialCategory;
  final CostCategory? categoryPreset;
  final String? initialCategoryId;
  final String? initialHouseId;
  final CostScope? initialScope;

  CostCategory? get effectiveCategory => initialCategory ?? categoryPreset;

  @override
  State<CostFormScreen> createState() => _CostFormScreenState();
}

class _CostFormScreenState extends State<CostFormScreen> {
  @override
  void initState() {
    super.initState();
    final cat = widget.effectiveCategory;
    context.read<CostFormBloc>().add(
      CostFormStarted(
        initialCost: widget.initialCost,
        initialCategory: cat,
        initialCategoryId: widget.initialCategoryId ?? cat?.id,
        defaultHouseId: widget.initialHouseId,
        initialScope: widget.initialScope,
      ),
    );
  }

  void _onKeyPress(String key) {
    context.read<CostFormBloc>().add(CostFormKeypadPressed(key));
  }

  void _pickDate(CostFormState state) {
    final colors = AppColors.context(context);
    DateTime tempDate = state.purchaseDate;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) => Material(
        color: colors.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SizedBox(
          height: 310,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: colors.grey,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      Text(
                        'Select Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textColor,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          context
                              .read<CostFormBloc>()
                              .add(CostFormDateChanged(tempDate));
                          Navigator.of(ctx).pop();
                        },
                        child: Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 0.5, color: Color(0xFFEBEBEB)),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: state.purchaseDate,
                    minimumDate: DateTime(2020),
                    maximumDate: DateTime(2035),
                    onDateTimeChanged: (DateTime newDate) {
                      tempDate = newDate;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editNote(CostFormState state) {
    final colors = AppColors.context(context);
    final ctrl = TextEditingController(text: state.note);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Expense Note',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: colors.textPrimaryColor,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Dinner bazar with friends',
            filled: true,
            fillColor: colors.tileColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondaryColor)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              context.read<CostFormBloc>().add(CostFormNoteChanged(ctrl.text.trim()));
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _submitExpense(CostFormState state) {
    if (state.isMealPoolConflict) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Meal pool category "${state.selectedCategory?.name}" cannot be used for personal expenses. Please change category.',
          ),
          backgroundColor: const Color(0xFFC81E1E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (state.amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount greater than 0')),
      );
      return;
    }
    context.read<CostFormBloc>().add(const CostFormSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);
    final backgroundColor = colors.backgroundColor;
    final cardColor = colors.cardColor;
    final primaryColor = colors.primaryColor;
    final darkText = colors.textPrimaryColor;
    final subText = colors.textSecondaryColor;

    return BlocConsumer<CostFormBloc, CostFormState>(
      listenWhen: (previous, current) =>
          current.isSuccess != previous.isSuccess ||
          (current.errorMessage != null &&
              current.errorMessage != previous.errorMessage),
      listener: (context, state) {
        if (state.isSuccess) {
          context.read<HouseContextCubit>().notifyCostUpdated();
          context.pop(true);
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      builder: (context, state) {
        final category = state.selectedCategory;
        final categoryName = category?.name ?? 'Food & Bazar';
        final categoryDesc = category?.isFood == true
            ? 'Rice & Fish Bazar'
            : 'Household & Utilities';

        final now = DateTime.now();
        final isToday =
            state.purchaseDate.year == now.year &&
            state.purchaseDate.month == now.month &&
            state.purchaseDate.day == now.day;
        final dateLabel = isToday
            ? 'TODAY'
            : DateFormat('d MMM').format(state.purchaseDate).toUpperCase();

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            leading: const AppBackButton(icon: Icons.close_rounded),
            title: Text(state.isEditing ? 'Edit Expense' : 'Add Expense'),
          ),
          body: SafeArea(
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 10,),
                    // ── Category Section ──────────────────────────────────
                    // Header: Select a category: & + New
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select a category:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                        InkWell(
                          onTap: () => _showNewCategoryDialog(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 15,
                                  color: darkText,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'New',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: darkText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                
                    // Category Selection Card (Single clean white card)
                    InkWell(
                      onTap: () => _showCategoryPicker(context, state),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Category icon with soft peach background & subtle border
                            CategoryIconView(
                              icon: category?.icon,
                              categoryName: categoryName,
                              size: 44,
                              fallbackEmoji: '🏷️',
                            ),
                            const SizedBox(width: 14),
                
                            // Category text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    categoryName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: darkText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    categoryDesc,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                
                            // Dropdown chevron
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 22,
                              color: subText,
                            ),
                          ],
                        ),
                      ),
                    ),
                
                    if (state.isMealPoolConflict) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE8E8),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFF8B4B4),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFE02424),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Meal Pool Not Allowed for Personal Account',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF9B1C1C),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '"$categoryName" is linked to meal pooling. Meal pool expenses are divided by house meal ratios and are only supported for shared houses. Please change the category or switch to a shared house.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9B1C1C),
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () =>
                                        _showCategoryPicker(context, state),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE02424),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Change Category',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                
                    // ── Box 2: Account, Member, Amount & Keypad Card (Bottom Box) ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ── Account & Member Selector Row ─────────────
                          Row(
                            children: [
                              // Account Selector Pill
                              Expanded(
                                child: InkWell(
                                  onTap: () =>
                                      _showAccountPicker(context, state),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9F9F9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: state.costScope == CostScope.personal
                                                ? const Color(0xFF8C8D8E)
                                                : const Color(0xFF2E7D32),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            state.costScope == CostScope.personal
                                                ? 'Personal'
                                                : (state.selectedHouse?.name ?? 'House'),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: darkText,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 16,
                                          color: subText,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                    
                              // Depositor / Paid-by Pill
                              Expanded(
                                child: InkWell(
                                  onTap: () =>
                                      _showPayerPicker(context, state),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9F9F9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.account_circle_outlined,
                                          size: 15,
                                          color: primaryColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            state.costScope == CostScope.personal
                                                ? 'Paid: You'
                                                : 'Paid: ${state.selectedPayerName ?? "You"}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: darkText,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        if (state.costScope == CostScope.shared)
                                          Icon(
                                            state.isCurrentUserAdmin
                                                ? Icons.keyboard_arrow_down_rounded
                                                : Icons.lock_outline_rounded,
                                            size: 14,
                                            color: subText,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    
                          const SizedBox(height: 50,),
                    
                          // Amount & Note Display Container
                          InkWell(
                            onTap: () => _editNote(state),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF8F5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Amount display
                                  Row(
                                    children: [
                                      Text(
                                        '৳ ${state.displayAmount}',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: primaryColor,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Note line
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.description_outlined,
                                        size: 14,
                                        color: subText,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          state.note.isNotEmpty
                                              ? state.note
                                              : 'Tap to add note or details...',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: state.note.isNotEmpty
                                                ? darkText
                                                : subText,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 50),

                          // ── Custom 4x4 Keypad ────────────────────────
                          CostKeypad(
                            onKeyPress: _onKeyPress,
                            onPickDate: () => _pickDate(state),
                            dateLabel: dateLabel,
                            onSubmit: () => _submitExpense(state),
                            isSubmitting: state.isSubmitting,
                            primaryColor: primaryColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCategoryPicker(BuildContext context, CostFormState state) {
    CostCategoryPickerSheet.show(
      context: context,
      state: state,
      onCategorySelected: (cat) {},
    );
  }

  void _showAccountPicker(BuildContext context, CostFormState state) {
    CostAccountPickerSheet.show(context: context, state: state);
  }

  Future<void> _showNewCategoryDialog(BuildContext context) async {
    final state = context.read<CostFormBloc>().state;
    final houseId = state.selectedHouseId ??
        (state.availableHouses.isNotEmpty
            ? state.availableHouses.first.id
            : null);
    final houseName = state.selectedHouse?.name ??
        (state.availableHouses.isNotEmpty
            ? state.availableHouses.first.name
            : 'Personal');

    final result = await Navigator.of(context).push<CostCategory>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CostCategoryFormScreen(
          initialHouseId: houseId,
          initialHouseName: houseName,
        ),
      ),
    );

    if (!context.mounted) return;
    if (result != null) {
      context.read<CostFormBloc>().add(CostFormCategoryChanged(result));
    }
  }

  void _showPayerPicker(BuildContext context, CostFormState state) {
    CostPayerPickerSheet.show(context, state);
  }
}
