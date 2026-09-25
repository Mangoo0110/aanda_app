import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/core/shared/widget/app_back_button.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/cost/domain/entities/category_emoji.dart';
import 'package:aanda/src/features/cost/domain/usecases/cost_usecases.dart';
import 'package:aanda/src/features/cost/presentation/bloc/cost_category_form/cost_category_form_bloc.dart';
import 'package:aanda/src/features/cost/presentation/helpers/category_color_helper.dart';
import 'package:aanda/src/features/cost/presentation/widgets/category_icon_view.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';

class CostCategoryFormScreen extends StatelessWidget {
  const CostCategoryFormScreen({
    super.key,
    this.initialHouseId,
    this.initialHouseName,
  });

  final String? initialHouseId;
  final String? initialHouseName;

  @override
  Widget build(BuildContext context) {
    final houseContext = context.read<HouseContextCubit>().state;
    final resolvedHouseId = initialHouseId ?? houseContext.activeAccountId;
    final resolvedHouseName = initialHouseName ?? houseContext.activeAccount?.name;

    return BlocProvider(
      create: (ctx) => CostCategoryFormBloc(
        createCostCategory: ctx.read<CreateCostCategory>(),
        initialHouseId: resolvedHouseId,
      ),
      child: _CostCategoryFormView(
        initialHouseId: resolvedHouseId,
        initialHouseName: resolvedHouseName,
      ),
    );
  }
}

class _CostCategoryFormView extends StatefulWidget {
  const _CostCategoryFormView({
    this.initialHouseId,
    this.initialHouseName,
  });

  final String? initialHouseId;
  final String? initialHouseName;

  @override
  State<_CostCategoryFormView> createState() => _CostCategoryFormViewState();
}

class _CostCategoryFormViewState extends State<_CostCategoryFormView> {
  // Theme constants matching modern purple aesthetic
  static const Color backgroundColor = Color(0xFFFAF9F7);
  static const Color cardColor = Colors.white;
  static const Color primaryPurple = Color(0xFF6C47FF);
  static const Color secondaryContainer = Color(0xFFEDE9FF);
  static const Color darkText = Color(0xFF141414);
  static const Color subText = Color(0xFF78716C);
  static const Color inputBg = Color(0xFFFAF9F7);
  static const Color borderColor = Color(0xFFEEEAE4);

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();

  String? _selectedHouseId;
  String _selectedHouseName = '';
  List<House> _availableHouses = [];

  // Image upload & in-house presets
  String? _pickedImagePath;
  String? _selectedImageUrl;
  String? _selectedEmoji;
  List<CategoryEmoji> _inHousePresets = CategoryEmoji.defaultEmojis;
  String? _selectedPresetId;

  // Cost nature: default to 'variable'
  String _costNature = 'variable';

  // Meal costing link
  bool _isMealCosting = false;

  @override
  void initState() {
    super.initState();
    final houseContext = context.read<HouseContextCubit>().state;
    _selectedHouseId = widget.initialHouseId ?? houseContext.activeAccountId;
    _selectedHouseName =
        widget.initialHouseName ?? houseContext.activeAccount?.name ?? '';
    _loadHouses();
    _loadInHousePresets();
  }

  Future<void> _loadInHousePresets() async {
    try {
      final getCategoryEmojis = context.read<GetCategoryEmojis>();
      final result = await getCategoryEmojis(const GetCategoryEmojisParams());
      if (mounted && result.data != null && result.data!.isNotEmpty) {
        setState(() {
          _inHousePresets = result.data!;
        });
      }
    } catch (_) {}
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
            final active = context.read<HouseContextCubit>().state.activeAccount;
            _selectedHouseId = active?.id ?? houses.first.id;
            _selectedHouseName = active?.name ?? houses.first.name;
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

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _pickedImagePath = picked.path;
          _selectedImageUrl = null;
          _selectedEmoji = null;
          _selectedPresetId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select image: $e')),
        );
      }
    }
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
                const Divider(color: borderColor),
                ..._availableHouses.map(
                  (house) => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: house.id == _selectedHouseId
                            ? secondaryContainer
                            : inputBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.home_work_rounded,
                        color: house.id == _selectedHouseId
                            ? primaryPurple
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
                        ? const Icon(Icons.check_rounded, color: primaryPurple)
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

  void _saveCategory() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    if (_selectedHouseId == null || _selectedHouseId!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account for this category')),
      );
      return;
    }

    final bloc = context.read<CostCategoryFormBloc>();
    bloc.add(CostCategoryNameChanged(name));
    bloc.add(CostCategoryHouseChanged(_selectedHouseId));
    bloc.add(CostCategoryNatureChanged(_costNature));
    bloc.add(CostCategoryFoodToggled(_isMealCosting));

    if (_pickedImagePath != null) {
      bloc.add(CostCategoryImageFilePicked(_pickedImagePath!));
    } else if (_selectedEmoji != null) {
      bloc.add(CostCategoryEmojiSelected(_selectedEmoji!));
    } else if (_selectedImageUrl != null) {
      bloc.add(CostCategoryPresetImageSelected(_selectedImageUrl!));
    }

    if (_costNature != 'variable') {
      bloc.add(CostCategoryDefaultAmountChanged(double.tryParse(_amountController.text.trim())));
    } else {
      bloc.add(const CostCategoryDefaultAmountChanged(null));
    }

    bloc.add(const CostCategorySubmitted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CostCategoryFormBloc, CostCategoryFormState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status ||
          (prev.errorMessage == null && curr.errorMessage != null),
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.isSuccess && state.createdCategory != null) {
          context.pop(state.createdCategory);
        }
      },
      builder: (context, state) {
        final isSubmitting = state.isSubmitting;
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
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: secondaryContainer,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: (_pickedImagePath != null ||
                                            _selectedImageUrl != null ||
                                            _selectedEmoji != null)
                                        ? CategoryIconView(
                                            icon: _pickedImagePath ??
                                                _selectedImageUrl ??
                                                _selectedEmoji,
                                            categoryName:
                                                _nameController.text.trim(),
                                            size: 46,
                                            borderRadius: 12,
                                          )
                                        : const Icon(
                                            Icons.category_rounded,
                                            color: primaryPurple,
                                            size: 26,
                                          ),
                                  ),
                                ),
                                Positioned(
                                  bottom: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: primaryPurple,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryPurple.withValues(alpha: 0.35),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                                      hintText: 'e.g. Electricity, Groceries...',
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
                      const Divider(color: borderColor, height: 1),
                      const SizedBox(height: 16),

                      // Header row for Icon Selection
                      Row(
                        children: [
                          const Text(
                            'SELECT ICON',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.9,
                              color: subText,
                            ),
                          ),
                          const Spacer(),
                          if (_pickedImagePath != null ||
                              _selectedImageUrl != null ||
                              _selectedEmoji != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _pickedImagePath = null;
                                  _selectedImageUrl = null;
                                  _selectedEmoji = null;
                                  _selectedPresetId = null;
                                });
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryPurple,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Compact, modern Icon Palette (5 items per row)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _inHousePresets.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isCustomPicked = _pickedImagePath != null ||
                                _selectedImageUrl != null;
                            return Tooltip(
                              message: 'Upload custom image',
                              child: InkWell(
                                onTap: _pickImage,
                                borderRadius: BorderRadius.circular(14),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  decoration: BoxDecoration(
                                    color: isCustomPicked
                                        ? secondaryContainer
                                        : inputBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: isCustomPicked
                                        ? Border.all(color: primaryPurple, width: 2)
                                        : null,
                                  ),
                                  child: Center(
                                    child: isCustomPicked
                                        ? CategoryIconView(
                                            icon: _pickedImagePath ??
                                                _selectedImageUrl,
                                            size: 32,
                                            borderRadius: 8,
                                          )
                                        : const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons
                                                    .add_photo_alternate_outlined,
                                                color: primaryPurple,
                                                size: 22,
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                'Upload',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: primaryPurple,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            );
                          }

                          final preset = _inHousePresets[index - 1];
                          final isSelected = _selectedPresetId == preset.id ||
                              (_pickedImagePath == null &&
                                  _selectedImageUrl == null &&
                                  _selectedEmoji == preset.emoji);

                          return Tooltip(
                            message: preset.name,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedPresetId = preset.id;
                                  _selectedEmoji = preset.emoji;
                                  _selectedImageUrl = null;
                                  _pickedImagePath = null;
                                  if (_nameController.text.trim().isEmpty ||
                                      _inHousePresets.any(
                                        (p) =>
                                            p.name ==
                                            _nameController.text.trim(),
                                      )) {
                                    _nameController.text = preset.name;
                                  }
                                  _costNature = preset.costNature;
                                  _isMealCosting = _selectedHouseId == null
                                      ? false
                                      : preset.isFood;
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryPurple.withValues(alpha: 0.12)
                                      : inputBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryPurple
                                        : Colors.transparent,
                                    width: isSelected ? 2.2 : 0,
                                  ),
                                ),
                                child: Center(
                                  child: CategoryIconView(
                                    icon: preset.emoji,
                                    categoryName: preset.name,
                                    backgroundColor:
                                        CategoryColorHelper.fromHex(
                                      preset.color,
                                    ),
                                    size: 38,
                                    fallbackEmoji: preset.emoji,
                                  ),
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
                          color: secondaryContainer,
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
                          children: [
                            const Text(
                              'Link to Meal Costing',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: darkText,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _selectedHouseId == null
                                  ? 'Meal costing is only supported for shared houses with meal tracking.'
                                  : 'Settled by meal ratio (User Meals × Total Meal Cost ÷ Total Meals)',
                              maxLines: 3,
                              style: const TextStyle(
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
                        value: _selectedHouseId == null ? false : _isMealCosting,
                        onChanged: _selectedHouseId == null
                            ? null
                            : (val) => setState(() => _isMealCosting = val),
                        activeThumbColor: Colors.white,
                        activeTrackColor: primaryPurple,
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
                                      color: borderColor,
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
                                              color: primaryPurple,
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
                      colors: [Color(0xFF7C5CFC), Color(0xFF6C47FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: primaryPurple.withValues(alpha: 0.28),
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
                      onTap: isSubmitting ? null : _saveCategory,
                      borderRadius: BorderRadius.circular(26),
                      child: Center(
                        child: isSubmitting
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
      },
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
