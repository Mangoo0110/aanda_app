import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/features/profile/domain/entities/user_profile.dart';

class ProfileRemoteDatasource {
  ProfileRemoteDatasource({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  Future<Map<String, dynamic>> getProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    
    final currentUser = _supabase.auth.currentUser;
    final isOnboarded = currentUser?.userMetadata?['is_onboarded'] as bool? ?? false;
    final email = currentUser?.email ?? '';

    final result = Map<String, dynamic>.from(response);
    result['is_onboarded'] = isOnboarded;
    result['email'] = email;
    return result;
  }

  Future<Map<String, dynamic>> updateProfile(UserProfile profile) async {
    final updateData = <String, dynamic>{
      if (profile.fullName != null) 'full_name': profile.fullName,
      if (profile.avatarUrl != null) 'avatar_url': profile.avatarUrl,
      if (profile.country != null) 'country': profile.country,
      if (profile.gender != null) 'gender': profile.gender,
      if (profile.ageRange != null) 'age_range': profile.ageRange,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('profiles')
        .upsert({
          'id': profile.id,
          'username': profile.username.isNotEmpty
              ? profile.username
              : (profile.email.isNotEmpty
                  ? profile.email.split('@').first
                  : 'user'),
          ...updateData,
        })
        .select()
        .single();

    // Also update Supabase auth metadata so session has it immediately
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            if (profile.fullName != null) 'full_name': profile.fullName,
            if (profile.country != null) 'country': profile.country,
            if (profile.gender != null) 'gender': profile.gender,
            if (profile.ageRange != null) 'age_range': profile.ageRange,
          },
        ),
      );
    } catch (_) {
      // Non-critical if user metadata sync fails
    }

    final result = Map<String, dynamic>.from(response);
    result['email'] = _supabase.auth.currentUser?.email ?? profile.email;
    result['is_onboarded'] = _supabase.auth.currentUser?.userMetadata?['is_onboarded'] ?? false;
    return result;
  }

  Future<String> uploadAvatar({
    required String userId,
    required List<int> fileBytes,
    required String fileExtension,
  }) async {
    final ext = fileExtension.replaceAll('.', '').toLowerCase();
    final path = '$userId/avatar.$ext';
    final mime = ext == 'png'
        ? 'image/png'
        : (ext == 'webp' ? 'image/webp' : 'image/jpeg');

    await _supabase.storage.from('avatars').uploadBinary(
      path,
      Uint8List.fromList(fileBytes),
      fileOptions: FileOptions(upsert: true, contentType: mime),
    );

    final rawUrl = _supabase.storage.from('avatars').getPublicUrl(path);
    // Cache bust query
    return '$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> markOnboarded(String userId) async {
    await _supabase.auth.updateUser(
      UserAttributes(
        data: {'is_onboarded': true},
      ),
    );
  }
}
