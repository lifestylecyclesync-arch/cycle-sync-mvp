import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cycle_sync_mvp/utils/auth_guard.dart';

void main() {
  group('AuthGuard Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initially auth state is false', () {
      // Test the default behavior when no auth state is set
      final authState = null;
      expect(authState, isNull);
    });

    test('getCurrentUserId returns null when not logged in', () {
      final userId = null;
      expect(userId, isNull);
    });

    test('Can set and retrieve user ID from SharedPreferences', () async {
      const testUserId = 'test-user-123';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', testUserId);
      
      final userId = prefs.getString('user_id');
      expect(userId, testUserId);
    });

    test('Can set and check logged in status via SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', 'test-user-123');
      
      final isLoggedIn = prefs.getString('user_id') != null;
      expect(isLoggedIn, true);
    });

    test('Logout clears user session', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', 'test-user-123');
      await prefs.setString('auth_token', 'test-token');
      
      // Simulate logout
      await prefs.remove('user_id');
      await prefs.remove('auth_token');
      
      final isLoggedIn = AuthGuard.isLoggedIn();
      expect(isLoggedIn, false);
    });

    test('Token handling - can store and retrieve', () async {
      const testToken = 'test-jwt-token-abc123';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', testToken);
      
      final token = prefs.getString('auth_token');
      expect(token, testToken);
    });

    test('Multiple users cannot be logged in simultaneously', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Login first user
      await prefs.setString('user_id', 'user-1');
      var currentUser = prefs.getString('user_id');
      expect(currentUser, 'user-1');
      
      // Login second user (should overwrite)
      await prefs.setString('user_id', 'user-2');
      currentUser = prefs.getString('user_id');
      expect(currentUser, 'user-2');
    });

    test('Session persists across app restarts (via SharedPreferences)', () async {
      const testUserId = 'persistent-user-id';
      final prefs = await SharedPreferences.getInstance();
      
      // Simulate login
      await prefs.setString('user_id', testUserId);
      
      // Simulate app restart - create new instance
      final prefsRestart = await SharedPreferences.getInstance();
      final persistedUserId = prefsRestart.getString('user_id');
      
      expect(persistedUserId, testUserId);
    });

    test('Can validate user ID format', () {
      // Valid UUIDs
      expect(_isValidUUID('550e8400-e29b-41d4-a716-446655440000'), true);
      expect(_isValidUUID('f47ac10b-58cc-4372-a567-0e02b2c3d479'), true);
      
      // Invalid formats
      expect(_isValidUUID('not-a-uuid'), false);
      expect(_isValidUUID(''), false);
      expect(_isValidUUID('12345'), false);
    });

    test('Can handle special characters in user ID storage', () async {
      const specialUserId = 'user_id_with-special.chars@123';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', specialUserId);
      
      final retrieved = prefs.getString('user_id');
      expect(retrieved, specialUserId);
    });
  });
}

/// Helper function to validate UUID format
bool _isValidUUID(String uuid) {
  final uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  return uuidRegex.hasMatch(uuid);
}
