import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_form/cost_form_bloc.dart';

class CostFormScreen extends StatefulWidget {
  const CostFormScreen({super.key});

  @override
  State<CostFormScreen> createState() => _CostFormScreenState();
}

class _CostFormScreenState extends State<CostFormScreen> {
  String _amountStr = '1200';
  String _noteStr = 'Dinner bazar with friends';
  bool _isMealPoolOn = true;
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

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      if (mounted) {
        context.read<CostFormBloc>().add(CostFormDateChanged(picked));
      }
    }
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
          CostFormScopeChanged(
            _isMealPoolOn ? CostScope.shared : CostScope.personal,
          ),
        );

    context.read<CostFormBloc>().add(const CostFormSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFFF7EE);
    const cardColor = Colors.white;
    const primaryCoral = Color(0xFFD85A38);
    const darkText = Color(0xFF1B1D1F);
    const subText = Color(0xFF8C8D8E);

    return BlocConsumer<CostFormBloc, CostFormState>(
      listener: (context, state) {
        if (state.isSuccess) {
          context.pop(true);
        } else if (state.errorMessage != null) {
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
        final categoryDesc = category?.isFood == true ? 'Rice & Fish Bazar' : 'Household & Utilities';

        final houseName = state.availableHouses.isNotEmpty
            ? state.availableHouses.first.name
            : 'Dhaka Flat';
        final bool isMealPoolApplicable = true; // TODO:: True only if seleceted account for expenses entry is a shared house not personal account.

        final now = DateTime.now();
        final isToday = _selectedDate.year == now.year &&
            _selectedDate.month == now.month &&
            _selectedDate.day == now.day;
        final dateLabel = isToday
            ? 'TODAY'
            : DateFormat('d MMM').format(_selectedDate).toUpperCase();

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // ── Top Bar ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      // Back Button
                      InkWell(
                        onTap: () => context.pop(),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cardColor,
                            shape: BoxShape.circle
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: darkText,
                          ),
                        ),
                      ),

                      // Title
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Add Expense',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // ── Box 1: Category & Scope Card (Top Box) ───────────
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: SELECT CATEGORY & + New
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'SELECT CATEGORY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: subText,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _showNewCategoryDialog(context),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryCoral.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_rounded,
                                            size: 14,
                                            color: primaryCoral,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            'New',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: primaryCoral,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Category Selection Tile
                              InkWell(
                                onTap: () => _showCategoryPicker(context, state),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F9F9),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      // Category icon
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: primaryCoral.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '🍱',
                                            style: TextStyle(fontSize: 22),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Category text
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 18,
                                          color: subText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Sub-row: House selector pill & Meal Pool toggle pill
                              Row(
                                children: [
                                  // Left pill: Dhaka Flat
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9F9F9),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              houseName,
                                              maxLines: 2,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: darkText,
                                              ),
                                              overflow: TextOverflow.ellipsis,
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
                                  const SizedBox(width: 10),

                                  // Right pill: Meal Pool: ON / OFF
                                  if(isMealPoolApplicable) InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isMealPoolOn = !_isMealPoolOn;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isMealPoolOn
                                            ? primaryCoral.withValues(alpha: 0.12)
                                            : const Color(0xFFF4F4F4),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isMealPoolOn
                                                ? Icons.check_circle_rounded
                                                : Icons.radio_button_unchecked,
                                            size: 14,
                                            color: _isMealPoolOn
                                                ? primaryCoral
                                                : subText,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            _isMealPoolOn
                                                ? 'Meal Pool: ON'
                                                : 'Meal Pool: OFF',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _isMealPoolOn
                                                  ? primaryCoral
                                                  : subText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Box 2: Amount & Keypad Card (Bottom Box) ─────────
                        Expanded(
                          child: Container(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Amount display
                                        Row(
                                          children: [
                                            Text(
                                              '৳ ${_amountStr.isEmpty ? '0' : _amountStr}',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w700,
                                                color: primaryCoral,
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

                                const Spacer(),

                                // ── Custom 4x4 Keypad ────────────────────────
                                SizedBox(
                                  height: 250,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
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
                                            Expanded(
                                              child: _dateKey(dateLabel),
                                            ),
                                            const SizedBox(height: 8),

                                            // Row 2: Backspace Key
                                            Expanded(
                                              child: _backspaceKey(),
                                            ),
                                            const SizedBox(height: 8),

                                            // Rows 3 & 4: Big 2-row Submit Button
                                            Expanded(
                                              flex: 2,
                                              child: _submitButton(
                                                state,
                                                primaryCoral,
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
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
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
              : const Icon(
                  Icons.check_rounded,
                  size: 32,
                  color: Colors.white,
                ),
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
                const SizedBox(height: 16),
                const Text(
                  'Select Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1D1F),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: state.availableCategories.length,
                    itemBuilder: (context, index) {
                      final cat = state.availableCategories[index];
                      final isSel = state.selectedCategory?.id == cat.id;
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD85A38).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.category_rounded,
                            color: Color(0xFFD85A38),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          cat.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: cat.isFood
                            ? const Text('Meal / Food Bazar',
                                style: TextStyle(fontSize: 12))
                            : null,
                        trailing: isSel
                            ? const Icon(Icons.check_rounded,
                                color: Color(0xFFD85A38))
                            : null,
                        onTap: () {
                          context
                              .read<CostFormBloc>()
                              .add(CostFormCategoryChanged(cat));
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

  void _showNewCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'New Category',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Category Name',
                filled: true,
                fillColor: const Color(0xFFFAF8F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                filled: true,
                fillColor: const Color(0xFFFAF8F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                final cat = CostCategory(
                  id: name.toLowerCase().replaceAll(' ', '_'),
                  name: name,
                  isFood: true,
                );
                context
                    .read<CostFormBloc>()
                    .add(CostFormCategoryChanged(cat));
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
