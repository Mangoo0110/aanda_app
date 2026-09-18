import 'package:aanda/src/core/theme/app_colors.dart';
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
                          SizedBox(
                            height: 250,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // First 3 columns (Grid: 3 cols x 4 rows)
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            _key('7'),
                                            _key('8'),
                                            _key('9'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            _key('4'),
                                            _key('5'),
                                            _key('6'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            _key('1'),
                                            _key('2'),
                                            _key('3'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            _key('.'),
                                            _key('0'),
                                            _key('00'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                    
                                // 4th column (Date, Backspace, Big Submit Button)
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    children: [
                                      // Row 1: TODAY Date Key
                                      Expanded(child: _dateKey(dateLabel)),
                                      const SizedBox(height: 8),
                    
                                      // Row 2: Backspace Key
                                      Expanded(child: _backspaceKey()),
                                      const SizedBox(height: 8),
                    
                                      // Rows 3 & 4: Big 2-row Submit Button
                                      Expanded(
                                        flex: 2,
                                        child: _submitButton(
                                          state,
                                          primaryColor,
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

  // ── Keypad Keys ────────────────────────────────────────────────────────────

  Widget _key(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _onKeyPress(label),
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1D1F),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateKey(String label) {
    return Material(
      color: const Color(0xFFEFECE6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Color(0xFF1B1D1F),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B1D1F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backspaceKey() {
    return Material(
      color: const Color(0xFFF6F6F6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _onKeyPress('⌫'),
        borderRadius: BorderRadius.circular(16),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 18,
            color: Color(0xFF1B1D1F),
          ),
        ),
      ),
    );
  }

  Widget _submitButton(CostFormState state, Color primaryCoral) {
    return Material(
      color: primaryCoral,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: state.isSubmitting ? null : () => _submitExpense(state),
        borderRadius: BorderRadius.circular(22),
        child: Center(
          child: state.isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Icon(Icons.check_rounded, size: 32, color: Colors.white),
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, CostFormState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B1D1F),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _showNewCategoryDialog(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 14,
                              color: Color(0xFF1B1D1F),
                            ),
                            SizedBox(width: 3),
                            Text(
                              'New',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B1D1F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: state.availableCategories.length,
                    itemBuilder: (context, index) {
                      final cat = state.availableCategories[index];
                      final isSel = state.selectedCategory?.id == cat.id;
                      final isEmoji =
                          cat.icon != null &&
                          cat.icon!.isNotEmpty &&
                          cat.icon!.length <= 4 &&
                          int.tryParse(cat.icon!) == null;

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFFEBEBEB)
                                : const Color(0xFFF6F6F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: isEmoji
                                ? Text(
                                    cat.icon!,
                                    style: const TextStyle(fontSize: 18),
                                  )
                                : const Icon(
                                    Icons.category_rounded,
                                    color: Color(0xFF4A4D50),
                                    size: 18,
                                  ),
                          ),
                        ),
                        title: Text(
                          cat.name,
                          style: TextStyle(
                            fontWeight: isSel
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14,
                            color: const Color(0xFF1B1D1F),
                          ),
                        ),
                        subtitle: (cat.costNature != 'variable' &&
                                cat.defaultAmount != null &&
                                cat.defaultAmount! > 0)
                            ? Text(
                                'Default: ৳${cat.defaultAmount!.toInt()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8C8D8E),
                                ),
                              )
                            : null,
                        trailing: isSel
                            ? const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF1B1D1F),
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          context.read<CostFormBloc>().add(
                            CostFormCategoryChanged(cat),
                          );
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
                          Navigator.of(ctx).pop();
                        },
                      );
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

    if (result != null && mounted) {
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

  void _showAccountPicker(BuildContext context, CostFormState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Select Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1D1F),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Personal Account option
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF475467),
                  size: 20,
                ),
              ),
              title: const Text(
                'Personal Account',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B1D1F),
                ),
              ),
              subtitle: const Text(
                'Only visible to you',
                style: TextStyle(fontSize: 12, color: Color(0xFF8C8D8E)),
              ),
              trailing: state.costScope == CostScope.personal
                  ? const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF1B1D1F),
                      size: 20,
                    )
                  : null,
              onTap: () {
                context.read<CostFormBloc>().add(
                      const CostFormHouseChanged(null),
                    );
                Navigator.of(ctx).pop();
              },
            ),

            if (state.availableHouses.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'SHARED HOUSES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFF8C8D8E),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ...state.availableHouses.map((house) {
                final isSelected = state.costScope == CostScope.shared &&
                    state.selectedHouseId == house.id;
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF8F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.home_work_rounded,
                      color: Color(0xFF1E824C),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    house.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: const Color(0xFF1B1D1F),
                    ),
                  ),
                  subtitle: const Text(
                    'Shared house account',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8C8D8E)),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF1B1D1F),
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    context.read<CostFormBloc>().add(
                          CostFormHouseChanged(house.id),
                        );
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showPayerPicker(BuildContext context, CostFormState state) {
    if (state.costScope == CostScope.personal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Personal expenses are always recorded for yourself.'),
        ),
      );
      return;
    }

    if (!state.isCurrentUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Only house admins can record expenses on behalf of other members.',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Paid / Deposited By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1D1F),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'Admin override: select who paid this expense',
                style: TextStyle(fontSize: 12, color: Color(0xFF8C8D8E)),
              ),
            ),
            const SizedBox(height: 14),

            if (state.members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'No members found for this house.',
                    style: TextStyle(color: Color(0xFF8C8D8E)),
                  ),
                ),
              )
            else
              ...state.members.map((m) {
                final isSelected = m.userId == state.selectedPayerId;
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFFDEEE9),
                    backgroundImage:
                        m.avatarUrl != null && m.avatarUrl!.isNotEmpty
                            ? NetworkImage(m.avatarUrl!)
                            : null,
                    child: m.avatarUrl == null || m.avatarUrl!.isEmpty
                        ? Text(
                            m.displayName.isNotEmpty
                                ? m.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Color(0xFFD85A38),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Row(
                    children: [
                      Text(
                        m.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: const Color(0xFF1B1D1F),
                        ),
                      ),
                      if (m.isAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F4F7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475467),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF1B1D1F),
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    context.read<CostFormBloc>().add(
                          CostFormPayerChanged(
                            payerId: m.userId,
                            payerName: m.displayName,
                          ),
                        );
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
