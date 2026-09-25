import 'package:flutter_test/flutter_test.dart';
import 'package:aanda/src/core/error_handler/friendly_error.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/profile/domain/entities/user_profile.dart';

void main() {
  group('FriendlyError Mapping', () {
    test('maps socket and network errors to friendly no internet message', () {
      final error1 = FriendlyError.from('SocketException: Failed host lookup: supabase.co');
      expect(error1.isNetwork, isTrue);
      expect(error1.title, 'No internet connection');
      expect(error1.message, 'Please check your internet connection and try again.');

      final error2 = FriendlyError.from('ClientException with SocketException: Connection refused');
      expect(error2.isNetwork, isTrue);
      expect(error2.title, 'No internet connection');

      final error3 = FriendlyError.from('NetworkError: connection timed out');
      expect(error3.isNetwork, isTrue);
      expect(error3.title, 'No internet connection');
    });

    test('maps generic and unexpected exceptions to friendly generic message', () {
      final error1 = FriendlyError.from(Exception('Internal database constraint failure'));
      expect(error1.isNetwork, isFalse);
      expect(error1.title, 'Something unexpected happened');
      expect(error1.message, 'Please try again later!');

      final error2 = FriendlyError.from(null);
      expect(error2.isNetwork, isFalse);
      expect(error2.title, 'Something unexpected happened');
      expect(error2.message, 'Please try again later!');
    });
  });

  group('UserProfile Completeness', () {
    test('incomplete profile when demographic fields are missing and not onboarded', () {
      const profile = UserProfile(
        id: 'user-123',
        email: 'user@trackbanana.com',
        username: 'banana_user',
      );

      expect(profile.isComplete, isFalse);
    });

    test('complete profile when country, gender, and ageRange are set', () {
      const profile = UserProfile(
        id: 'user-123',
        email: 'user@trackbanana.com',
        username: 'banana_user',
        country: 'Bangladesh',
        gender: 'Male',
        ageRange: '25–34',
      );

      expect(profile.isComplete, isTrue);
    });

    test('complete profile when isOnboarded flag is set to true', () {
      const profile = UserProfile(
        id: 'user-123',
        email: 'user@trackbanana.com',
        username: 'banana_user',
        isOnboarded: true,
      );

      expect(profile.isComplete, isTrue);
    });

    test('UserProfile serialization roundtrip', () {
      const profile = UserProfile(
        id: 'user-456',
        email: 'test@trackbanana.com',
        username: 'test_user',
        fullName: 'Anik Saha',
        avatarUrl: 'https://example.com/avatar.png',
        country: 'Bangladesh',
        gender: 'Male',
        ageRange: '25–34',
        isOnboarded: true,
      );

      final map = profile.toMap();
      final reconstituted = UserProfile.fromMap(map, email: 'test@trackbanana.com');

      expect(reconstituted.id, profile.id);
      expect(reconstituted.username, profile.username);
      expect(reconstituted.fullName, profile.fullName);
      expect(reconstituted.avatarUrl, profile.avatarUrl);
      expect(reconstituted.country, profile.country);
      expect(reconstituted.gender, profile.gender);
      expect(reconstituted.ageRange, profile.ageRange);
    });
  });

  group('House Entity & Avatar Support', () {
    test('House copyWith updates avatarUrl correctly', () {
      final house = House(
        id: 'h-1',
        name: 'TrackBanana House',
        createdBy: 'u-1',
        createdAt: DateTime.now(),
      );

      expect(house.avatarUrl, isNull);

      final updated = house.copyWith(avatarUrl: 'https://example.com/house.png');
      expect(updated.avatarUrl, 'https://example.com/house.png');
      expect(updated.name, 'TrackBanana House');
      expect(updated.id, 'h-1');
    });
  });
}

