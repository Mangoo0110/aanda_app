import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aanda/src/app/bloc/house_context/house_context_cubit.dart';
import 'package:aanda/src/app/routing/app_routes.dart';
import 'package:aanda/src/core/shared/widget/app_back_button.dart';
import 'package:aanda/src/core/theme/app_colors.dart';
import 'package:aanda/src/core/utils/helpers/avatar_image_provider.dart';
import 'package:aanda/src/features/profile/domain/entities/user_profile.dart';
import 'package:aanda/src/features/profile/presentation/cubit/profile_cubit.dart';

class ProfileOnboardingScreen extends StatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  State<ProfileOnboardingScreen> createState() => _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends State<ProfileOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Selected values
  File? _localImageFile;
  String? _selectedCountry;
  String? _selectedGender;
  String? _selectedAgeRange;
  bool _isSaving = false;

  final List<Map<String, String>> _countries = const [
    {'name': 'Bangladesh', 'code': 'BD', 'flag': '🇧🇩'},
    {'name': 'United States', 'code': 'US', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'code': 'GB', 'flag': '🇬🇧'},
    {'name': 'Canada', 'code': 'CA', 'flag': '🇨🇦'},
    {'name': 'Australia', 'code': 'AU', 'flag': '🇦🇺'},
    {'name': 'Germany', 'code': 'DE', 'flag': '🇩🇪'},
    {'name': 'India', 'code': 'IN', 'flag': '🇮🇳'},
    {'name': 'Singapore', 'code': 'SG', 'flag': '🇸🇬'},
    {'name': 'United Arab Emirates', 'code': 'AE', 'flag': '🇦🇪'},
    {'name': 'Saudi Arabia', 'code': 'SA', 'flag': '🇸🇦'},
    {'name': 'Malaysia', 'code': 'MY', 'flag': '🇲🇾'},
    {'name': 'Japan', 'code': 'JP', 'flag': '🇯🇵'},
    {'name': 'France', 'code': 'FR', 'flag': '🇫🇷'},
    {'name': 'Netherlands', 'code': 'NL', 'flag': '🇳🇱'},
    {'name': 'Sweden', 'code': 'SE', 'flag': '🇸🇪'},
  ];

  String _countrySearch = '';

  final List<Map<String, dynamic>> _genders = const [
    {'label': 'Male', 'icon': Icons.male_rounded},
    {'label': 'Female', 'icon': Icons.female_rounded},
    {'label': 'Non-binary', 'icon': Icons.transgender_rounded},
    {'label': 'Prefer not to say', 'icon': Icons.person_outline_rounded},
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
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
        setState(() {
          _localImageFile = File(picked.path);
        });
      }
    } catch (_) {}
  }

  Future<void> _finishOnboarding() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final cubit = context.read<ProfileCubit>();
    final session = Supabase.instance.client.auth.currentSession;
    final userId = session?.user.id;

    if (userId != null) {
      String? avatarUrl = cubit.state.profile?.avatarUrl;

      if (_localImageFile != null) {
        try {
          final bytes = await _localImageFile!.readAsBytes();
          final ext = _localImageFile!.path.split('.').last;
          avatarUrl = await cubit.uploadAvatar(
            userId: userId,
            bytes: bytes,
            extension: ext,
          );
        } catch (e) {
          if (mounted) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload photo: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (avatarUrl == null) {
          if (mounted) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(cubit.state.errorMessage ?? 'Failed to upload photo'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final existingProfile = cubit.state.profile ??
          UserProfile(
            id: userId,
            email: session?.user.email ?? '',
            username: session?.user.email?.split('@').first ?? 'user',
          );

      final updated = existingProfile.copyWith(
        avatarUrl: avatarUrl ?? existingProfile.avatarUrl,
        country: _selectedCountry ?? existingProfile.country,
        gender: _selectedGender ?? existingProfile.gender,
        ageRange: _selectedAgeRange ?? existingProfile.ageRange,
        isOnboarded: true,
      );

      await cubit.updateProfile(updated);
      await cubit.completeOnboarding(userId);
      if (mounted) {
        context.read<HouseContextCubit>().load();
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    context.go(AppRoutes.home);
  }

  void _onSkip() {
    _finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.context(context);

    return Scaffold(
      backgroundColor: colors.appBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Step Progress and Skip
            _buildHeader(colors),

            // Wizard Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (step) => setState(() => _currentStep = step),
                children: [
                  _buildAvatarStep(colors),
                  _buildCountryStep(colors),
                  _buildGenderStep(colors),
                  _buildAgeRangeStep(colors),
                ],
              ),
            ),

            // Bottom Navigation Buttons
            _buildBottomBar(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                AppBackButton(
                  onPressed: _previousPage,
                  margin: EdgeInsets.zero,
                )
              else
                const SizedBox(width: 40),
              Text(
                'Step ${_currentStep + 1} of 4',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              TextButton(
                onPressed: _onSkip,
                style: TextButton.styleFrom(
                  splashFactory: NoSplash.splashFactory,
                ),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 4.0,
              minHeight: 4,
              backgroundColor: colors.softGrey,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Avatar ──────────────────────────────────────────────────────────
  Widget _buildAvatarStep(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Add a Profile Photo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help your housemates recognize you easily',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),

          // Avatar display with camera overlay
          GestureDetector(
            onTap: () => _showImageSourceSheet(colors),
            child: Stack(
              children: [
                Container(
                  width: 136,
                  height: 136,
                  decoration: BoxDecoration(
                    color: colors.softGrey,
                    shape: BoxShape.circle,
                    image: _localImageFile != null
                        ? DecorationImage(
                            image: FileImage(_localImageFile!),
                            fit: BoxFit.cover,
                          )
                        : (getAvatarImageProvider(context.watch<ProfileCubit>().state.profile?.avatarUrl) != null
                            ? DecorationImage(
                                image: getAvatarImageProvider(context.watch<ProfileCubit>().state.profile?.avatarUrl)!,
                                fit: BoxFit.cover,
                              )
                            : null),
                  ),
                  child: (_localImageFile == null &&
                          getAvatarImageProvider(context.watch<ProfileCubit>().state.profile?.avatarUrl) == null)
                      ? Icon(
                          Icons.person_rounded,
                          size: 72,
                          color: colors.textSecondary.withValues(alpha: 0.5),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action button
          TextButton.icon(
            onPressed: () => _showImageSourceSheet(colors),
            style: TextButton.styleFrom(
              splashFactory: NoSplash.splashFactory,
            ),
            icon: Icon(Icons.photo_library_rounded, color: colors.primaryColor, size: 18),
            label: Text(
              _localImageFile != null ? 'Change photo' : 'Choose photo',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.primaryColor,
              ),
            ),
          ),
        ],
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

  // ── Step 2: Country ────────────────────────────────────────────────────────
  Widget _buildCountryStep(AppColors colors) {
    final filtered = _countries
        .where((c) =>
            c['name']!.toLowerCase().contains(_countrySearch.toLowerCase()))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Where are you located?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select your primary country or region',
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),

          // Search bar (borderless)
          Container(
            decoration: BoxDecoration(
              color: colors.softGrey,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: colors.textSecondary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _countrySearch = val),
                    style: TextStyle(color: colors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search country...',
                      hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // List of countries
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final country = filtered[index];
                final isSelected = _selectedCountry == country['name'];

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedCountry = country['name']);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.primaryColor.withValues(alpha: 0.12)
                            : colors.softGrey,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Text(country['flag']!, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              country['name']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? colors.primaryColor : colors.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, color: colors.primaryColor, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Gender ─────────────────────────────────────────────────────────
  Widget _buildGenderStep(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'What is your gender?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Used to tailor your housemate and profile experience',
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          ..._genders.map((g) {
            final isSelected = _selectedGender == g['label'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedGender = g['label'] as String),
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primaryColor.withValues(alpha: 0.12)
                          : colors.softGrey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          g['icon'] as IconData,
                          color: isSelected ? colors.primaryColor : colors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            g['label'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? colors.primaryColor : colors.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: colors.primaryColor, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Step 4: Age Range ──────────────────────────────────────────────────────
  Widget _buildAgeRangeStep(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'What is your age range?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Help us personalize relevant features for you',
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _ageRanges.map((age) {
              final isSelected = _selectedAgeRange == age;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedAgeRange = age),
                  borderRadius: BorderRadius.circular(24),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primaryColor.withValues(alpha: 0.14)
                          : colors.softGrey,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          age,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? colors.primaryColor : colors.textPrimary,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle_rounded, color: colors.primaryColor, size: 18),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar(AppColors colors) {
    final isLastStep = _currentStep == 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isSaving ? null : _nextPage,
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
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isLastStep ? 'Complete Profile' : 'Continue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
