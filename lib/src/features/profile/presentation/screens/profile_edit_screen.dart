import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/core/shared/widget/app_back_button.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/utils/helpers/avatar_image_provider.dart';
import 'package:aanda/src/features/profile/domain/entities/user_profile.dart';
import 'package:aanda/src/features/profile/presentation/cubit/profile_cubit.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final ValueNotifier<File?> _imageFileNotifier = ValueNotifier<File?>(null);
  final ValueNotifier<String?> _countryNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _genderNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _ageRangeNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> _isSavingNotifier = ValueNotifier<bool>(false);

  ImageProvider? _cachedRemoteAvatarProvider;

  final List<String> _countries = const [
    'Bangladesh',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'India',
    'Singapore',
    'United Arab Emirates',
    'Saudi Arabia',
    'Malaysia',
    'Japan',
    'France',
    'Netherlands',
    'Sweden',
  ];

  final List<String> _genders = const [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  final List<String> _ageRanges = const [
    'Under 18',
    '18–24',
    '25–34',
    '35–44',
    '45–54',
    '55+',
  ];

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileCubit>().state.profile;
    if (profile != null) {
      _fullNameController.text = profile.fullName ?? '';
      _countryNotifier.value = profile.country;
      _genderNotifier.value = profile.gender;
      _ageRangeNotifier.value = profile.ageRange;
      if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
        _cachedRemoteAvatarProvider = getAvatarImageProvider(profile.avatarUrl);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _imageFileNotifier.dispose();
    _countryNotifier.dispose();
    _genderNotifier.dispose();
    _ageRangeNotifier.dispose();
    _isSavingNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        _imageFileNotifier.value = File(picked.path);
      }
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    if (_isSavingNotifier.value) return;
    _isSavingNotifier.value = true;

    final cubit = context.read<ProfileCubit>();
    final session = Supabase.instance.client.auth.currentSession;
    final userId = session?.user.id;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    if (userId != null) {
      String? avatarUrl = cubit.state.profile?.avatarUrl;
      final localFile = _imageFileNotifier.value;

      if (localFile != null) {
        try {
          final bytes = await localFile.readAsBytes();
          final ext = localFile.path.split('.').last;
          avatarUrl = await cubit.uploadAvatar(
            userId: userId,
            bytes: bytes,
            extension: ext,
          );
        } catch (e) {
          _isSavingNotifier.value = false;
          messenger.showSnackBar(
            SnackBar(
              content: Text('Failed to upload photo: $e'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (avatarUrl == null) {
          _isSavingNotifier.value = false;
          messenger.showSnackBar(
            SnackBar(
              content: Text(cubit.state.errorMessage ?? 'Failed to upload photo'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final existing = cubit.state.profile ??
          UserProfile(
            id: userId,
            email: session?.user.email ?? '',
            username: session?.user.email?.split('@').first ?? 'user',
          );

      final updated = existing.copyWith(
        fullName: _fullNameController.text.trim(),
        avatarUrl: avatarUrl ?? existing.avatarUrl,
        country: _countryNotifier.value ?? existing.country,
        gender: _genderNotifier.value ?? existing.gender,
        ageRange: _ageRangeNotifier.value ?? existing.ageRange,
      );

      final success = await cubit.updateProfile(updated);
      _isSavingNotifier.value = false;

      if (success) {
        if (mounted) {
          context.read<HouseContextCubit>().refresh();
        }
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        nav.pop();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(cubit.state.errorMessage ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      _isSavingNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
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
            child: ValueListenableBuilder<bool>(
              valueListenable: _isSavingNotifier,
              builder: (context, isSaving, _) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isSaving ? null : _saveProfile,
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
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Avatar Picker (Isolated Rebuild) ───────────────
            Center(
              child: ValueListenableBuilder<File?>(
                valueListenable: _imageFileNotifier,
                builder: (context, localFile, _) {
                  final ImageProvider? imageProvider = localFile != null
                      ? FileImage(localFile)
                      : _cachedRemoteAvatarProvider;

                  return GestureDetector(
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
                            child: imageProvider != null
                                ? Image(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                    width: 104,
                                    height: 104,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person_rounded,
                                      size: 52,
                                      color: colors.grey.withValues(alpha: 0.5),
                                    ),
                                  )
                                : Icon(
                                    Icons.person_rounded,
                                    size: 52,
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
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => _showImageSourceSheet(colors),
                style: TextButton.styleFrom(
                  splashFactory: NoSplash.splashFactory,
                ),
                child: Text(
                  'Change Photo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── 2. Full Name Input (Clean Borderless) ─────────────
            _buildSectionLabel(colors, 'Full Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _fullNameController,
              style: TextStyle(
                color: colors.textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
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
                hintText: 'Enter your full name',
                hintStyle: TextStyle(
                  color: colors.grey.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── 3. Country Selector (Isolated Rebuild) ───────────
            _buildSectionLabel(colors, 'Country'),
            const SizedBox(height: 8),
            ValueListenableBuilder<String?>(
              valueListenable: _countryNotifier,
              builder: (context, selectedCountry, _) {
                return Container(
                  decoration: BoxDecoration(
                    color: colors.softGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCountry,
                      hint: Text(
                        'Select Country',
                        style: TextStyle(
                          color: colors.grey.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      isExpanded: true,
                      dropdownColor: colors.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.grey),
                      items: _countries.map((c) {
                        return DropdownMenuItem<String>(
                          value: c,
                          child: Text(
                            c,
                            style: TextStyle(color: colors.textColor, fontSize: 15),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        _countryNotifier.value = val;
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // ── 4. Gender Selector (Isolated Rebuild) ────────────
            _buildSectionLabel(colors, 'Gender'),
            const SizedBox(height: 8),
            ValueListenableBuilder<String?>(
              valueListenable: _genderNotifier,
              builder: (context, selectedGender, _) {
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _genders.map((g) {
                    final isSelected = selectedGender == g;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _genderNotifier.value = g;
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.primaryColor.withValues(alpha: 0.12)
                                : colors.softGrey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            g,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? colors.primaryColor : colors.textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            // ── 5. Age Range Selector (Isolated Rebuild) ─────────
            _buildSectionLabel(colors, 'Age Range'),
            const SizedBox(height: 8),
            ValueListenableBuilder<String?>(
              valueListenable: _ageRangeNotifier,
              builder: (context, selectedAgeRange, _) {
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _ageRanges.map((age) {
                    final isSelected = selectedAgeRange == age;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _ageRangeNotifier.value = age;
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.primaryColor.withValues(alpha: 0.12)
                                : colors.softGrey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            age,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? colors.primaryColor : colors.textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(AppColors colors, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.textColor,
      ),
    );
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
}
