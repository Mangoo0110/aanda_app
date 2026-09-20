import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/shared/widget/app_back_button.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_form/cost_form_bloc.dart';
import 'package:aanda/src/features/cost/presentation/screens/cost_category_form_screen.dart';
import 'package:aanda/src/features/cost/presentation/widgets/cost_account_picker_sheet.dart';
import 'package:aanda/src/features/cost/presentation/widgets/cost_category_picker_sheet.dart';
import 'package:aanda/src/features/cost/presentation/widgets/cost_keypad.dart';
import 'package:aanda/src/features/cost/presentation/widgets/cost_payer_picker_sheet.dart';

class CostFormScreen extends StatefulWidget {
  const CostFormScreen({super.key});

  @override
  State<CostFormScreen> createState() => _CostFormScreenState();
}

class _CostFormScreenState extends State<CostFormScreen> {
  String _amountStr = '';
  String _noteStr = '';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<CostFormBloc>().add(const CostFormStarted());
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == '⌫') {
        if (_amountStr.isNotEmpty) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
          if (_amountStr.isEmpty) _amountStr = '0';
        }
      } else if (key == '.') {
        if (!_amountStr.contains('.')) {
          _amountStr = _amountStr.isEmpty ? '0.' : '$_amountStr.';
        }
      } else if (key == '00') {
        if (_amountStr != '0' && _amountStr.isNotEmpty) {
          _amountStr += '00';
        }
      } else {
        // Digits 0-9
        if (_amountStr == '0') {
          _amountStr = key;
        } else {
          // Check decimal places limit
          if (_amountStr.contains('.')) {
            final parts = _amountStr.split('.');
            if (parts.length > 1 && parts[1].length >= 2) return;
          }
          if (_amountStr.length < 9) {
            _amountStr += key;
          }
        }
      }
    });

    final val = double.tryParse(_amountStr) ?? 0.0;
    context.read<CostFormBloc>().add(CostFormAmountChanged(val));
  }

  void _pickDate() {
    DateTime tempDate = _selectedDate;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) => Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SizedBox(
          height: 310,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // Top Drag Handle
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header Toolbar: Cancel, Title, Done
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8C8D8E),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      const Text(
                        'Select Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B1D1F),
                          decoration: TextDecoration.none,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          setState(() => _selectedDate = tempDate);
                          context
                              .read<CostFormBloc>()
                              .add(CostFormDateChanged(tempDate));
                          Navigator.of(ctx).pop();
                        },
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B1D1F),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1, thickness: 0.5, color: Color(0xFFEBEBEB)),
              // Cupertino Date Wheel Picker
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
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

  void _editNote() {
    final ctrl = TextEditingController(text: _noteStr);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Expense Note',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Dinner bazar with friends',
            filled: true,
            fillColor: const Color(0xFFFAF8F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD85A38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              setState(() => _noteStr = ctrl.text.trim());
              context.read<CostFormBloc>().add(CostFormNoteChanged(_noteStr));
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _submitExpense(CostFormState state) {
    final val = double.tryParse(_amountStr) ?? 0.0;
    if (val <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount greater than 0')),
      );
      return;
    }

    final categoryName = state.selectedCategory?.name ?? 'Food & Bazar';
    final name = _noteStr.isNotEmpty ? _noteStr : categoryName;

    context.read<CostFormBloc>().add(CostFormNameChanged(name));
    context.read<CostFormBloc>().add(CostFormAmountChanged(val));
    context.read<CostFormBloc>().add(CostFormNoteChanged(_noteStr));
    context.read<CostFormBloc>().add(CostFormDateChanged(_selectedDate));
    context.read<CostFormBloc>().add(
      CostFormScopeChanged(state.costScope),
    );

    context.read<CostFormBloc>().add(const CostFormSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFFF7EE);
    const cardColor = Colors.white;
    final primaryColor = Theme.of(context).colorScheme.primary;
    const darkText = Color(0xFF1B1D1F);
    const subText = Color(0xFF8C8D8E);

    return BlocConsumer<CostFormBloc, CostFormState>(
      listenWhen: (previous, current) =>
          current.isSuccess != previous.isSuccess ||
          (current.errorMessage != null &&
              current.errorMessage != previous.errorMessage),
      listener: (context, state) {
        if (state.isSuccess) {
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
            _selectedDate.year == now.year &&
            _selectedDate.month == now.month &&
            _selectedDate.day == now.day;
        final dateLabel = isToday
            ? 'TODAY'
            : DateFormat('d MMM').format(_selectedDate).toUpperCase();

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            leading: const AppBackButton(icon: Icons.close_rounded),
            title: const Text('Add Expense'),
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
                        const Text(
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
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 15,
                                  color: darkText,
                                ),
                                SizedBox(width: 3),
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
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF2EE),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFFFDCD3),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  category?.icon ?? '🍱',
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
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
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: darkText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    categoryDesc,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: subText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                
                            // Dropdown chevron
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 22,
                              color: subText,
                            ),
                          ],
                        ),
                      ),
                    ),
                
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
                                            color: state.costScope ==
                                                    CostScope.personal
                                                ? const Color(0xFF8C8D8E)
                                                : const Color(0xFF2E7D32),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            state.costScope ==
                                                    CostScope.personal
                                                ? 'Personal'
                                                : (state.selectedHouse?.name ??
                                                    'House'),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: darkText,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        const Icon(
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
                                            state.costScope ==
                                                    CostScope.personal
                                                ? 'Paid: You'
                                                : 'Paid: ${state.selectedPayerName ?? "You"}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: darkText,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        if (state.costScope ==
                                            CostScope.shared)
                                          Icon(
                                            state.isCurrentUserAdmin
                                                ? Icons
                                                    .keyboard_arrow_down_rounded
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
                            onTap: _editNote,
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
                                        '৳ ${_amountStr.isEmpty ? '0' : _amountStr}',
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
                                      const Icon(
                                        Icons.description_outlined,
                                        size: 14,
                                        color: subText,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _noteStr.isNotEmpty
                                              ? _noteStr
                                              : 'Tap to add note or details...',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _noteStr.isNotEmpty
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
                    
                          SizedBox(height: 50,),
                    
                          // ── Custom 4x4 Keypad ────────────────────────
                          CostKeypad(
                            onKeyPress: _onKeyPress,
                            onPickDate: _pickDate,
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
      onCategorySelected: (cat) {
        if (cat.costNature != 'variable' &&
            cat.defaultAmount != null &&
            cat.defaultAmount! > 0) {
          final amt = cat.defaultAmount!;
          setState(() {
            _amountStr = amt % 1 == 0
                ? amt.toInt().toString()
                : amt.toString();
          });
        }
      },
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
      if (result.costNature != 'variable' &&
          result.defaultAmount != null &&
          result.defaultAmount! > 0) {
        final amt = result.defaultAmount!;
        setState(() {
          _amountStr = amt % 1 == 0 ? amt.toInt().toString() : amt.toString();
        });
      }
    }
  }

  void _showPayerPicker(BuildContext context, CostFormState state) {
    CostPayerPickerSheet.show(context, state);
  }
}
