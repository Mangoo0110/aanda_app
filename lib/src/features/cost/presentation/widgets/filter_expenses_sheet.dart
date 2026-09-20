import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_feed/cost_feed_bloc.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';

class FilterExpensesSheet extends StatefulWidget {
  const FilterExpensesSheet({
    super.key,
    required this.state,
    required this.memberCount,
    required this.onApply,
    required this.onReset,
  });

  final CostFeedState state;
  final int memberCount;
  final void Function(
    Sprint? sprint,
    String? payerId,
    String? categoryId,
    CostScope? scope,
  ) onApply;
  final VoidCallback onReset;

  static void show({
    required BuildContext context,
    required CostFeedState state,
    required int memberCount,
    required void Function(
      Sprint? sprint,
      String? payerId,
      String? categoryId,
      CostScope? scope,
    ) onApply,
    required VoidCallback onReset,
  }) {
    final bloc = context.read<CostFeedBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: bloc,
        child: FilterExpensesSheet(
          state: state,
          memberCount: memberCount,
          onApply: onApply,
          onReset: onReset,
        ),
      ),
    );
  }

  @override
  State<FilterExpensesSheet> createState() => _FilterExpensesSheetState();
}

class _FilterExpensesSheetState extends State<FilterExpensesSheet> {
  Sprint? _selectedSprint;
  String? _selectedPayerId;
  String? _selectedCategoryId;
  CostScope? _selectedScope;

  @override
  void initState() {
    super.initState();
    _selectedSprint = widget.state.selectedSprint;
    _selectedPayerId = widget.state.selectedPayerId;
    _selectedCategoryId = widget.state.selectedCategoryId;
    _selectedScope = widget.state.selectedScope;
  }

  int get _activeCount {
    int count = 0;
    if (_selectedSprint != null) count++;
    if (_selectedPayerId != null) count++;
    if (_selectedCategoryId != null) count++;
    if (_selectedScope != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    const primaryCoral = Color(0xFFD85A38);
    const darkText = Color(0xFF1B1D1F);
    const subText = Color(0xFF8C8D8E);
    const unselectedChipBg = Color(0xFFF4F4F4);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title Row with Active badge, Reset all, and close X
            Row(
              children: [
                const Text(
                  'Filter Expenses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),
                const SizedBox(width: 8),
                if (_activeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: primaryCoral.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_activeCount Active',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primaryCoral,
                      ),
                    ),
                  ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSprint = null;
                      _selectedPayerId = null;
                      _selectedCategoryId = null;
                      _selectedScope = null;
                    });
                    widget.onReset();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      'Reset all',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryCoral,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: darkText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Section 1: SETTLEMENT CYCLE ─────────────────────────────────
            const Text(
              'BILLING CYCLE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: subText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.state.sprints.isNotEmpty) ...[
                  ...widget.state.sprints.map((s) {
                    final isSel = _selectedSprint?.id == s.id;
                    final label = s.isOpen
                        ? 'Current Cycle (${s.dateRangeFormatted} → Active)'
                        : s.label;
                    return _filterChip(
                      label: label,
                      isSelected: isSel,
                      onTap: () => setState(() {
                        _selectedSprint = isSel ? null : s;
                      }),
                      primaryColor: primaryCoral,
                      unselectedBg: unselectedChipBg,
                    );
                  }),
                ] else ...[
                  _filterChip(
                    label: 'Current Cycle (16 Sep → Active)',
                    isSelected: _selectedSprint == null,
                    onTap: () => setState(() => _selectedSprint = null),
                    primaryColor: primaryCoral,
                    unselectedBg: unselectedChipBg,
                  ),
                ],
                _filterChip(
                  label: 'Custom 📅',
                  isSelected: false,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (date != null && context.mounted) {
                      context.read<CostFeedBloc>().add(
                        CostFeedMonthChanged(date),
                      );
                    }
                  },
                  primaryColor: primaryCoral,
                  unselectedBg: unselectedChipBg,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Section 2: TAG / EXPENSE POOL ───────────────────────────────
            const Text(
              'TAG / EXPENSE POOL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: subText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(
                  label: 'All Tags',
                  isSelected:
                      _selectedScope == null && _selectedCategoryId == null,
                  onTap: () => setState(() {
                    _selectedScope = null;
                    _selectedCategoryId = null;
                  }),
                  primaryColor: primaryCoral,
                  unselectedBg: unselectedChipBg,
                ),
                _filterChip(
                  label: 'Bazar (Pool)',
                  isSelected:
                      _selectedScope == CostScope.shared &&
                      _isCategoryMatch('bazar'),
                  onTap: () => setState(() {
                    _selectedScope = CostScope.shared;
                    _selectedCategoryId = _findCategoryId('bazar');
                  }),
                  primaryColor: primaryCoral,
                  unselectedBg: unselectedChipBg,
                ),
                _filterChip(
                  label: 'Groceries',
                  isSelected: _isCategoryMatch('grocer'),
                  onTap: () => setState(() {
                    _selectedCategoryId = _findCategoryId('grocer');
                  }),
                  primaryColor: primaryCoral,
                  unselectedBg: unselectedChipBg,
                ),
                _filterChip(
                  label: 'Utilities',
                  isSelected: _isCategoryMatch('utilit'),
                  onTap: () => setState(() {
                    _selectedCategoryId = _findCategoryId('utilit');
                  }),
                  primaryColor: primaryCoral,
                  unselectedBg: unselectedChipBg,
                ),
                _filterChip(
                  label: 'Personal',
                  isSelected: _selectedScope == CostScope.personal,
                  onTap: () => setState(() {
                    _selectedScope = CostScope.personal;
                    _selectedCategoryId = null;
                  }),
                  primaryColor: primaryCoral,
                  unselectedBg: unselectedChipBg,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Section 3: PAID BY MEMBER ───────────────────────────────────
            const Text(
              'PAID BY MEMBER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: subText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(
                  label: 'All Members',
                  isSelected: _selectedPayerId == null,
                  onTap: () => setState(() => _selectedPayerId = null),
                  primaryColor: primaryCoral,
                  unselectedBg: unselectedChipBg,
                ),
                ...widget.state.uniquePayers.map((p) {
                  final isSel = _selectedPayerId == p.id;
                  final initial = p.name.isNotEmpty
                      ? p.name[0].toUpperCase()
                      : 'M';
                  return _memberFilterChip(
                    label: p.name,
                    initial: initial,
                    isSelected: isSel,
                    onTap: () => setState(() {
                      _selectedPayerId = isSel ? null : p.id;
                    }),
                    primaryColor: primaryCoral,
                    unselectedBg: unselectedChipBg,
                  );
                }),
              ],
            ),
            const SizedBox(height: 26),

            // ── Bottom Action Buttons ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () {
                      widget.onApply(
                        _selectedSprint,
                        _selectedPayerId,
                        _selectedCategoryId,
                        _selectedScope,
                      );
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: primaryCoral,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Apply Filters (${widget.state.displayCosts.length} entries)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isCategoryMatch(String keyword) {
    if (_selectedCategoryId == null) return false;
    final cat = widget.state.categories
        .where((c) => c.id == _selectedCategoryId)
        .firstOrNull;
    return cat?.name.toLowerCase().contains(keyword) ?? false;
  }

  String? _findCategoryId(String keyword) {
    return widget.state.categories
        .where((c) => c.name.toLowerCase().contains(keyword))
        .firstOrNull
        ?.id;
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color unselectedBg,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : unselectedBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF1B1D1F),
          ),
        ),
      ),
    );
  }

  Widget _memberFilterChip({
    required String label,
    required String initial,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color unselectedBg,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : unselectedBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 11,
              backgroundColor: isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFFD97706),
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF1B1D1F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
