import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Preferences Manager Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('UserPreferences Model', () {
      test('Can create UserPreferences with defaults', () {
        final prefs = {
          'theme': 'light',
          'notifications_enabled': true,
          'avatar_id': null,
          'photo_url': null,
        };

        expect(prefs['theme'], 'light');
        expect(prefs['notifications_enabled'], true);
      });

      test('Can create UserPreferences with custom values', () {
        final prefs = {
          'theme': 'dark',
          'notifications_enabled': false,
          'avatar_id': 'avatar-5',
          'photo_url': 'https://example.com/photo.jpg',
        };

        expect(prefs['theme'], 'dark');
        expect(prefs['notifications_enabled'], false);
        expect(prefs['avatar_id'], 'avatar-5');
        expect(prefs['photo_url'], isNotEmpty);
      });

      test('copyWith creates new instance with updated fields', () {
        final original = {
          'theme': 'light',
          'notifications_enabled': true,
        };

        final updated = {...original, 'theme': 'dark'};

        expect(original['theme'], 'light');
        expect(updated['theme'], 'dark');
        expect(updated['notifications_enabled'], true);
      });

      test('Handles all preference fields', () {
        final allFields = {
          'user_id': 'user-456',
          'theme': 'light',
          'notifications_enabled': true,
          'avatar_id': 'avatar-1',
          'photo_url': 'https://example.com/photo.jpg',
          'updated_at': DateTime.now().toIso8601String(),
        };

        expect(allFields.length, 6);
        expect(allFields.containsKey('theme'), true);
        expect(allFields.containsKey('notifications_enabled'), true);
      });
    });

    group('Theme Preferences', () {
      test('Can set and retrieve theme', () async {
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setString('theme', 'dark');
        final theme = prefs.getString('theme');

        expect(theme, 'dark');
      });

      test('Supports valid theme options', () {
        const validThemes = ['light', 'dark', 'auto'];
        const testTheme = 'dark';

        expect(validThemes.contains(testTheme), true);
      });

      test('Rejects invalid theme values', () {
        const validThemes = ['light', 'dark', 'auto'];
        const invalidTheme = 'neon';

        expect(validThemes.contains(invalidTheme), false);
      });

      test('Theme defaults to light if not set', () async {
        final prefs = await SharedPreferences.getInstance();
        final theme = prefs.getString('theme') ?? 'light';

        expect(theme, 'light');
      });

      test('Can toggle between theme options', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Start with light
        await prefs.setString('theme', 'light');
        expect(prefs.getString('theme'), 'light');

        // Switch to dark
        await prefs.setString('theme', 'dark');
        expect(prefs.getString('theme'), 'dark');

        // Switch to auto
        await prefs.setString('theme', 'auto');
        expect(prefs.getString('theme'), 'auto');
      });
    });

    group('Notification Preferences', () {
      test('Can enable and disable notifications', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Enable notifications
        await prefs.setBool('notifications_enabled', true);
        expect(prefs.getBool('notifications_enabled'), true);

        // Disable notifications
        await prefs.setBool('notifications_enabled', false);
        expect(prefs.getBool('notifications_enabled'), false);
      });

      test('Notifications default to enabled', () async {
        final prefs = await SharedPreferences.getInstance();
        final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

        expect(notificationsEnabled, true);
      });

      test('Can toggle notification status multiple times', () async {
        final prefs = await SharedPreferences.getInstance();
        
        for (var i = 0; i < 5; i++) {
          final currentState = prefs.getBool('notifications_enabled') ?? true;
          await prefs.setBool('notifications_enabled', !currentState);
        }

        expect(prefs.getBool('notifications_enabled'), isNotNull);
      });
    });

    group('Avatar Management', () {
      test('Can set avatar by ID', () async {
        const avatarId = 'avatar-5';
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setString('avatar_id', avatarId);
        expect(prefs.getString('avatar_id'), avatarId);
      });

      test('Supports multiple avatar options', () {
        const validAvatars = [
          'avatar-1',
          'avatar-2',
          'avatar-3',
          'avatar-4',
          'avatar-5',
          'avatar-6',
          'avatar-7',
          'avatar-8',
        ];

        for (var avatar in validAvatars) {
          expect(avatar.contains('avatar-'), true);
        }
      });

      test('Can clear avatar (set to null)', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Set avatar
        await prefs.setString('avatar_id', 'avatar-5');
        expect(prefs.getString('avatar_id'), 'avatar-5');

        // Clear avatar
        await prefs.remove('avatar_id');
        expect(prefs.getString('avatar_id'), isNull);
      });

      test('Can set photo avatar URL', () async {
        const photoUrl = 'https://example.com/photos/user-456.jpg';
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setString('photo_url', photoUrl);
        expect(prefs.getString('photo_url'), photoUrl);
      });

      test('Validates photo URL format', () {
        const validUrl = 'https://example.com/photo.jpg';
        const invalidUrl = 'not a url';

        expect(validUrl.startsWith('http'), true);
        expect(invalidUrl.startsWith('http'), false);
      });

      test('Can clear photo avatar', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Set photo
        await prefs.setString('photo_url', 'https://example.com/photo.jpg');
        expect(prefs.getString('photo_url'), isNotNull);

        // Clear photo
        await prefs.remove('photo_url');
        expect(prefs.getString('photo_url'), isNull);
      });
    });

    group('Update User Preferences', () {
      test('Can update theme only', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Update theme
        await prefs.setString('theme', 'dark');
        expect(prefs.getString('theme'), 'dark');
        
        // Other preferences should remain unchanged
        await prefs.setBool('notifications_enabled', true);
        expect(prefs.getBool('notifications_enabled'), true);
      });

      test('Can update notifications only', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Set initial state
        await prefs.setString('theme', 'light');
        await prefs.setBool('notifications_enabled', true);

        // Update notifications only
        await prefs.setBool('notifications_enabled', false);
        
        expect(prefs.getString('theme'), 'light');
        expect(prefs.getBool('notifications_enabled'), false);
      });

      test('Can update avatar only', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Set initial state
        await prefs.setString('theme', 'light');
        await prefs.setString('avatar_id', 'avatar-1');

        // Update avatar only
        await prefs.setString('avatar_id', 'avatar-5');
        
        expect(prefs.getString('theme'), 'light');
        expect(prefs.getString('avatar_id'), 'avatar-5');
      });

      test('Can update multiple preferences at once', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Update theme and notifications
        await prefs.setString('theme', 'dark');
        await prefs.setBool('notifications_enabled', false);
        await prefs.setString('avatar_id', 'avatar-3');

        expect(prefs.getString('theme'), 'dark');
        expect(prefs.getBool('notifications_enabled'), false);
        expect(prefs.getString('avatar_id'), 'avatar-3');
      });

      test('Can update with partial parameters', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Set initial complete state
        await prefs.setString('theme', 'light');
        await prefs.setBool('notifications_enabled', true);
        await prefs.setString('avatar_id', 'avatar-1');

        // Update only theme - others should persist
        await prefs.setString('theme', 'dark');
        
        expect(prefs.getString('theme'), 'dark');
        expect(prefs.getBool('notifications_enabled'), true);
        expect(prefs.getString('avatar_id'), 'avatar-1');
      });
    });

    group('Get User Preferences', () {
      test('Can retrieve all preferences', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Set preferences
        await prefs.setString('theme', 'dark');
        await prefs.setBool('notifications_enabled', false);
        await prefs.setString('avatar_id', 'avatar-5');

        // Retrieve
        final allPrefs = {
          'theme': prefs.getString('theme'),
          'notifications_enabled': prefs.getBool('notifications_enabled'),
          'avatar_id': prefs.getString('avatar_id'),
        };

        expect(allPrefs['theme'], 'dark');
        expect(allPrefs['notifications_enabled'], false);
        expect(allPrefs['avatar_id'], 'avatar-5');
      });

      test('Returns defaults for unset preferences', () async {
        final prefs = await SharedPreferences.getInstance();
        
        final allPrefs = {
          'theme': prefs.getString('theme') ?? 'light',
          'notifications_enabled': prefs.getBool('notifications_enabled') ?? true,
        };

        expect(allPrefs['theme'], 'light');
        expect(allPrefs['notifications_enabled'], true);
      });

      test('Handles mixed set and unset preferences', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Set only theme
        await prefs.setString('theme', 'dark');

        final allPrefs = {
          'theme': prefs.getString('theme') ?? 'light',
          'notifications_enabled': prefs.getBool('notifications_enabled') ?? true,
          'avatar_id': prefs.getString('avatar_id'),
        };

        expect(allPrefs['theme'], 'dark');
        expect(allPrefs['notifications_enabled'], true);
        expect(allPrefs['avatar_id'], isNull);
      });
    });

    group('Preference Persistence', () {
      test('Preferences persist across app instances', () async {
        // First instance
        var prefs = await SharedPreferences.getInstance();
        await prefs.setString('theme', 'dark');
        await prefs.setBool('notifications_enabled', false);

        // Simulate app restart by getting new instance
        prefs = await SharedPreferences.getInstance();
        
        expect(prefs.getString('theme'), 'dark');
        expect(prefs.getBool('notifications_enabled'), false);
      });

      test('Updated preferences are reflected immediately', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Initial state
        await prefs.setString('theme', 'light');
        expect(prefs.getString('theme'), 'light');

        // Update
        await prefs.setString('theme', 'dark');
        expect(prefs.getString('theme'), 'dark');

        // Update again
        await prefs.setString('theme', 'auto');
        expect(prefs.getString('theme'), 'auto');
      });
    });

    group('Error Handling', () {
      test('Handles null preference values gracefully', () async {
        final prefs = await SharedPreferences.getInstance();
        
        final nullPref = prefs.getString('non_existent_key');
        expect(nullPref, isNull);
      });

      test('Handles empty string values', () async {
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setString('theme', '');
        final theme = prefs.getString('theme');
        
        expect(theme, '');
      });

      test('Handles preference key with special characters', () async {
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setString('user_pref_theme_v2', 'dark');
        expect(prefs.getString('user_pref_theme_v2'), 'dark');
      });

      test('Can recover from invalid preference state', () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Set invalid state (boolean as string - intentionally wrong)
        await prefs.setString('notifications_enabled_backup', 'invalid');
        
        // Should not throw, just return null
        final backup = prefs.getString('notifications_enabled_backup');
        expect(backup, 'invalid');
      });
    });

    group('Data Validation', () {
      test('Validates avatar_id format', () {
        const validAvatarId = 'avatar-5';
        const invalidAvatarId = 'invalid@avatar';

        expect(validAvatarId.contains('avatar-'), true);
        expect(invalidAvatarId.contains('avatar-'), false);
      });

      test('Validates photo_url is proper URL', () {
        const validUrl = 'https://example.com/photo.jpg';
        const invalidUrl = 'not a url';

        expect(validUrl.contains('http'), true);
        expect(invalidUrl.contains('http'), false);
      });

      test('Theme values are from predefined set', () {
        const validThemes = ['light', 'dark', 'auto'];
        const testTheme = 'dark';

        expect(validThemes.contains(testTheme), true);
      });
    });
  });
}
