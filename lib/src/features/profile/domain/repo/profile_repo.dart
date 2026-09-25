import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/features/profile/domain/entities/user_profile.dart';

abstract interface class ProfileRepo {
  /// Fetches the profile for the given [userId].
  AsyncRequest<UserProfile> getProfile({required String userId});

  /// Updates profile information in the profiles table and metadata.
  AsyncRequest<UserProfile> updateProfile({required UserProfile profile});

  /// Uploads avatar image file bytes to Supabase storage bucket and returns public URL.
  AsyncRequest<String> uploadAvatar({
    required String userId,
    required List<int> fileBytes,
    required String fileExtension,
  });

  /// Marks profile onboarding complete in user metadata.
  AsyncRequest<void> markOnboarded({required String userId});
}
