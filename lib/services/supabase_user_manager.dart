import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'supabase_service.dart';

class UserManager {
  static const String _table = 'users';

  // Get current user profile
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      String? userId = SupabaseService.getCurrentUserId();
      if (userId == null) return null;

      return await SupabaseService.fetchSingleRecord(_table, userId);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Register user - automatically creates user record via trigger
  static Future<bool> registerUser({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 registerUser() START - email: $email');
      final result = await SupabaseService.registerUser(email, password);
      print('🔐 registerUser() - Response: user=${result.user?.email}, hasSession=${result.session != null}');
      
      // Check if user was created
      if (result.user != null) {
        print('🔐 registerUser() - SUCCESS: Account created');
        return true;
      } else {
        print('🔐 registerUser() - FAILED: No user in response');
        return false;
      }
    } catch (e) {
      print('🔐 registerUser() CATCH - Type: ${e.runtimeType}, Message: $e');
      return false;
    }
  }

  // Login user
  static Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final result = await SupabaseService.loginUser(email, password);
      return result.user != null;
    } catch (e) {
      print('Login failed: $e');
      return false;
    }
  }

  // Logout
  static Future<void> logoutUser() async {
    try {
      await SupabaseService.logoutUser();
    } catch (e) {
      print('Logout failed: $e');
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final currentUser = SupabaseService.getCurrentUser();
    print('🔐 UserManager.isLoggedIn() - currentUser = $currentUser');
    return currentUser != null;
  }

  // Get user ID
  static Future<String?> getCurrentUserId() async {
    return SupabaseService.getCurrentUserId();
  }

  // Change password
  static Future<bool> changePassword(String newPassword) async {
    try {
      final user = SupabaseService.getCurrentUser();
      if (user != null) {
        await SupabaseService.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Change password failed: $e');
      return false;
    }
  }

  // Reset password request
  static Future<bool> resetPasswordRequest(String email) async {
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      print('Reset password request failed: $e');
      return false;
    }
  }

  // Google Sign-In
  static Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
        ],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('Google sign in cancelled');
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      final response = await SupabaseService.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      print('Google sign in successful: ${response.user?.email}');
      return response.user != null;
    } catch (e) {
      print('Google sign in error: $e');
      return false;
    }
  }
}
