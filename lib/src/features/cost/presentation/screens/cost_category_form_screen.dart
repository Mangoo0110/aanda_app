import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/core/shared/widget/app_back_button.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/cost/domain/entities/category_emoji.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/repo/cost_repo.dart';
import 'package:aanda/src/features/cost/domain/usecases/cost_usecases.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';

class CostCategoryFormScreen extends StatefulWidget {
  const CostCategoryFormScreen({
    super.key,
    this.initialHouseId,
    this.initialHouseName,
  });

  final String? initialHouseId;
  final String? initialHouseName;

  @override
  State<CostCategoryFormScreen> createState() => _CostCategoryFormScreenState();
}

class _CostCategoryFormScreenState extends State<CostCategoryFormScreen> {
  static const Color backgroundColor = Color(0xFFFFF7EE);
  static const Color cardColor = Colors.white;
  static const Color primaryCoral = Color(0xFFE05344);
  static const Color softPeach = Color(0xFFFDEEE8);
  static const Color darkText = Color(0xFF1B1D1F);
  static const Color subText = Color(0xFF8C8D8E);
  static const Color inputBg = Color(0xFFF9F7F4);

  final TextEditingController _nameController = TextEditingController(text: '');
  final TextEditingController _amountController = TextEditingController(
    text: '',
  );
  final FocusNode _amountFocusNode = FocusNode();

  // House selection
  String? _selectedHouseId;
  String _selectedHouseName = '';
  List<House> _availableHouses = [];

  // Emojis list (loaded from repo/cache or defaults)
  List<CategoryEmoji> _emojis = CategoryEmoji.defaultEmojis;
  String _selectedEmoji = '⚡';

  // Cost nature: 'fixed' or 'variable'
  String _costNature = 'fixed';

  // Meal costing link
  bool _isMealCosting = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final selectedHouse = context.read<HouseContextCubit>().state.selectedHouse;
    _selectedHouseId = widget.initialHouseId ?? selectedHouse?.id;
    _selectedHouseName =
        widget.initialHouseName ?? selectedHouse?.name ?? '';
    _loadHouses();
    _loadEmojis();
  }

  Future<void> _loadHouses() async {
    try {
      final getMyHouses = context.read<GetMyHouses>();
      final result = await getMyHouses(const NoParams());
      final houses = result.data;
      if (mounted && houses != null && houses.isNotEmpty) {
        setState(() {
          _availableHouses = houses;
          if (_selectedHouseId == null) {
            _selectedHouseId = houses.first.id;
            _selectedHouseName = houses.first.name;
          } else {
            final match = houses.where((h) => h.id == _selectedHouseId);
            if (match.isNotEmpty) {
              _selectedHouseName = match.first.name;
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadEmojis() async {
    try {
      final getEmojis = context.read<GetCategoryEmojis>();
      final result = await getEmojis(const GetCategoryEmojisParams());
      if (mounted && result.data != null && result.data!.isNotEmpty) {
        setState(() => _emojis = result.data!);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _showHousePicker() {
    if (_availableHouses.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Select House',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ..._availableHouses.map(
                  (house) => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: house.id == _selectedHouseId
                            ? softPeach
                            : inputBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.home_work_rounded,
                        color: house.id == _selectedHouseId
                            ? primaryCoral
                            : subText,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      house.name,
                      style: TextStyle(
                        fontWeight: house.id == _selectedHouseId
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: darkText,
                      ),
                    ),
                    trailing: house.id == _selectedHouseId
                        ? const Icon(Icons.check_rounded, color: primaryCoral)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedHouseId = house.id;
                        _selectedHouseName = house.name;
                      });
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    // Variable costs must NOT have a default amount setup
    final defaultAmt = _costNature == 'variable'
        ? null
        : double.tryParse(_amountController.text.trim());

    setState(() => _isSubmitting = true);

    final createData = CreateCostCategoryData(
      name: name,
      icon: _selectedEmoji,
      isFood: _isMealCosting,
      houseId: _selectedHouseId,
      defaultAmount: defaultAmt,
      costNature: _costNature,
    );

    CostCategory? createdCategory;
    try {
      final createCategoryUseCase = context.read<CreateCostCategory>();
      final result = await createCategoryUseCase(createData);
      createdCategory = result.data;
    } catch (_) {}

    // Fallback if not returned
    createdCategory ??= CostCategory(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      icon: _selectedEmoji,
      isFood: _isMealCosting,
      houseId: _selectedHouseId,
      defaultAmount: defaultAmt,
      costNature: _costNature,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      context.pop(createdCategory);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          leading: const AppBackButton(icon: Icons.close_rounded),
          title: const Text('Category Preset'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Account / House Selection Row (Moved down from AppBar) ───
                Padding(
                  padding: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TARGET ACCOUNT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                          color: subText,
                        ),
                      ),
                      InkWell(
                        onTap: _showHousePicker,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 160,
                                ),
                                child: Text(
                                  _selectedHouseName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: darkText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: subText,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Card 1: Category Name & Choose Icon ──────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Big Icon Preview + Category Name Field
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Big Icon Preview Box
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: softPeach,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    _selectedEmoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 11,
                                    color: subText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),

                          // Name input
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'CATEGORY NAME',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: subText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 42,
                                  child: TextField(
                                    controller: _nameController,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: darkText,
                                      letterSpacing: -0.2,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. Electricity & Utilities',
                                      hintStyle: TextStyle(
                                        color: Color(0xFFBBB6AF),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      isDense: true,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      const Divider(color: Color(0xFFF2ECE4), height: 1),
                      const SizedBox(height: 16),

                      // Choose Icon Header
                      const Text(
                        'CHOOSE ICON',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                          color: subText,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Emoji Grid (6 columns matching design mockup)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                        itemCount: _emojis.length,
                        itemBuilder: (context, index) {
                          final item = _emojis[index];
                          final isSelected = _selectedEmoji == item.emoji;
                          return InkWell(
                            onTap: () =>
                                setState(() => _selectedEmoji = item.emoji),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? softPeach : inputBg,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(
                                        color: primaryCoral,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  item.emoji,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Card 2: Link to Meal Costing Card ────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: softPeach,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('🍲', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Link to Meal Costing',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: darkText,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Settled by meal ratio (User Meals × Total Meal Cost ÷ Total Meals)',
                              maxLines: 3,
                              style: TextStyle(
                                fontSize: 12,
                                color: subText,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Switch(
                        value: _isMealCosting,
                        onChanged: (val) =>
                            setState(() => _isMealCosting = val),
                        activeThumbColor: Colors.white,
                        activeTrackColor: primaryCoral,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: const Color(0xFFE5DFD9),
                        trackOutlineColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Card 3: Cost Nature & Default Amount ─────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cost Nature Row with [ Fixed | Variable ] Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'COST NATURE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.9,
                              color: subText,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3EEE8),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _segmentButton(
                                  label: 'Fixed',
                                  isSelected: _costNature == 'fixed',
                                  onTap: () =>
                                      setState(() => _costNature = 'fixed'),
                                ),
                                _segmentButton(
                                  label: 'Variable',
                                  isSelected: _costNature == 'variable',
                                  onTap: () =>
                                      setState(() => _costNature = 'variable'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Variable costs shouldn't have default amount setup
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: _costNature == 'fixed'
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    child: Divider(
                                      color: Color(0xFFF2ECE4),
                                      height: 1,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 12),
                                    child: Text(
                                      'DEFAULT AMOUNT',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: subText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 48,
                                    child: TextField(
                                      focusNode: _amountFocusNode,
                                      controller: _amountController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: darkText,
                                        letterSpacing: -0.3,
                                      ),
                                      decoration: const InputDecoration(
                                        prefixIcon: Padding(
                                          padding: EdgeInsets.only(
                                            left: 12,
                                            right: 8,
                                          ),
                                          child: Text(
                                            '৳',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: primaryCoral,
                                            ),
                                          ),
                                        ),
                                        prefixIconConstraints: BoxConstraints(
                                          minWidth: 0,
                                          minHeight: 0,
                                        ),
                                        hintText: '0',
                                        hintStyle: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFBBB6AF),
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(color: backgroundColor),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SizedBox(
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE85847), Color(0xFFD64433)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: primaryCoral.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: InkWell(
                      onTap: _isSubmitting ? null : _saveCategory,
                      borderRadius: BorderRadius.circular(26),
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _segmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? darkText : subText,
          ),
        ),
      ),
    );
  }
}
