import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/core/shared/widget/app_back_button.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/features/house/presentation/bloc/house_create/house_create_bloc.dart';

class HouseCreateScreen extends StatefulWidget {
  const HouseCreateScreen({super.key});

  @override
  State<HouseCreateScreen> createState() => _HouseCreateScreenState();
}

class _HouseCreateScreenState extends State<HouseCreateScreen> {
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();
  File? _localImageFile;
  List<int>? _imageBytes;
  String? _imageExtension;
  String? _localValidationError;

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final ext = picked.name.split('.').last;
        setState(() {
          _localImageFile = File(picked.path);
          _imageBytes = bytes;
          _imageExtension = ext;
          _localValidationError = null;
        });
      }
    } catch (_) {}
  }

  void _showImageSourceSheet(AppColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.softGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.softGrey,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: colors.primaryColor),
                ),
                title: const Text('Take a photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.softGrey,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library_rounded, color: colors.primaryColor),
                ),
                title: const Text('Choose from gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    setState(() => _localValidationError = null);

    if (_imageBytes == null || _imageBytes!.isEmpty) {
      setState(() {
        _localValidationError = 'Please select a profile photo for the shared house.';
      });
      return;
    }

    final name = _nameController.text.trim();
    if (name.length < 2) {
      setState(() {
        _localValidationError = 'House name must be at least 2 characters.';
      });
      return;
    }

    context.read<HouseCreateBloc>().add(
          HouseCreateSubmitted(
            avatarBytes: _imageBytes,
            avatarExtension: _imageExtension,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return BlocConsumer<HouseCreateBloc, HouseCreateState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status ||
          (prev.errorMessage == null && curr.errorMessage != null),
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: colors.errorColor,
            ),
          );
        }
        if (state.isSuccess) {
          context.read<HouseContextCubit>().load();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('House "${state.name}" created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true);
        }
      },
      builder: (context, state) {
        final isSubmitting = state.isSubmitting;
        final displayError = _localValidationError ?? state.errorMessage;

        return Scaffold(
          backgroundColor: colors.appBackgroundColor,
          appBar: AppBar(
            title: Text(
              'Create Shared House',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: colors.textColor,
              ),
            ),
            backgroundColor: colors.appBackgroundColor,
            elevation: 0,
            centerTitle: true,
            leading: const AppBackButton(),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                height: 52,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isSubmitting ? null : _submit,
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: colors.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primaryColor.withValues(alpha: 0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Create House',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. House Profile Image Picker (Required) ───────────
                Center(
                  child: GestureDetector(
                    onTap: () => _showImageSourceSheet(colors),
                    child: Stack(
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            color: colors.softGrey,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: _localImageFile != null
                                ? Image.file(
                                    _localImageFile!,
                                    fit: BoxFit.cover,
                                    width: 104,
                                    height: 104,
                                  )
                                : Icon(
                                    Icons.home_work_rounded,
                                    size: 48,
                                    color: colors.grey.withValues(alpha: 0.5),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: colors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => _showImageSourceSheet(colors),
                    style: TextButton.styleFrom(
                      splashFactory: NoSplash.splashFactory,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _localImageFile != null ? 'Change House Photo' : 'Add House Photo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '*',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── 2. Title & Subtitle ──────────────────────────────
                Center(
                  child: Text(
                    'Start a Shared House',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colors.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Create a space for your roommates, flatmates, or family to track shared costs and split expenses.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.grey,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── 3. House Name Input ──────────────────────────────
                Text(
                  'House / Group Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  focusNode: _focusNode,
                  autofocus: false,
                  style: TextStyle(
                    color: colors.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.home_outlined, color: colors.grey),
                    hintText: 'e.g. Bachelor Pad, Flat 4B, Dhanmondi Mess',
                    hintStyle: TextStyle(
                      color: colors.grey.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    filled: true,
                    fillColor: colors.softGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  onChanged: (val) {
                    setState(() => _localValidationError = null);
                    context.read<HouseCreateBloc>().add(HouseCreateNameChanged(val));
                  },
                  onSubmitted: (_) => _submit(),
                ),

                // Error message display
                if (displayError != null && displayError.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          displayError,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // ── 4. Admin Notice Card ─────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.softGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You will automatically be set as the house admin and can invite roommates later.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.grey,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
