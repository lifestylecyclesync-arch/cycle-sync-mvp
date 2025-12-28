import 'package:flutter/material.dart';
import '../services/supabase_user_manager.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';

class AuthGuard {
  static bool _isLoggedIn = false;
  static String? _currentUserId;

  /// Initialize auth state (called on app startup)
  static Future<void> initialize() async {
    try {
      final isLoggedIn = await UserManager.isLoggedIn().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false, // If it times out, assume not logged in
      );
      _isLoggedIn = isLoggedIn;
      
      if (_isLoggedIn) {
        final userId = await UserManager.getCurrentUserId().timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
        _currentUserId = userId;
      }
    } catch (e) {
      print('Auth initialization error: $e');
      // Continue anyway - user can login when needed
      _isLoggedIn = false;
      _currentUserId = null;
    }
  }

  /// Check if user is logged in
  static bool isLoggedIn() {
    return _isLoggedIn;
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    return _currentUserId;
  }

  /// Update login state (call after successful login/register)
  static Future<void> updateLoginState() async {
    print('🔐 AuthGuard.updateLoginState() - START');
    _isLoggedIn = await UserManager.isLoggedIn();
    print('🔐 AuthGuard.updateLoginState() - isLoggedIn = $_isLoggedIn');
    if (_isLoggedIn) {
      _currentUserId = await UserManager.getCurrentUserId();
      print('🔐 AuthGuard.updateLoginState() - userId = $_currentUserId');
    }
    print('🔐 AuthGuard.updateLoginState() - END');
  }

  /// Update logout state
  static Future<void> logout() async {
    print('🔐 AuthGuard.logout() - START');
    try {
      // Call logout on UserManager to clear Supabase session
      await UserManager.logoutUser();
      print('🔐 AuthGuard.logout() - Supabase logout successful');
    } catch (e) {
      print('🔐 AuthGuard.logout() - Supabase logout error: $e');
    }
    // Clear local auth state
    _isLoggedIn = false;
    _currentUserId = null;
    print('🔐 AuthGuard.logout() - Local state cleared, END');
  }

  /// Show login/register dialog overlay
  static Future<bool> requireAuth(BuildContext context) async {
    print('🔐 AuthGuard.requireAuth() - START');
    if (_isLoggedIn) {
      print('🔐 AuthGuard.requireAuth() - Already logged in, returning true');
      return true; // Already logged in
    }

    bool authSuccessful = false;
    
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _AuthDialog(
        onAuthSuccess: () async {
          print('🔐 AuthGuard.requireAuth() - onAuthSuccess callback triggered');
          // Update auth state immediately after successful registration/login
          await updateLoginState();
          authSuccessful = _isLoggedIn;
          print('🔐 AuthGuard.requireAuth() - authSuccessful = $authSuccessful');
          // Close the dialog
          if (dialogContext.mounted) {
            print('🔐 AuthGuard.requireAuth() - Closing dialog with Navigator.pop()');
            Navigator.pop(dialogContext, true);
          }
        },
      ),
    );

    print('🔐 AuthGuard.requireAuth() - Dialog closed, result = $result, authSuccessful = $authSuccessful');
    if (result == true && authSuccessful) {
      print('🔐 AuthGuard.requireAuth() - Auth successful, returning true');
      return true;
    }

    print('🔐 AuthGuard.requireAuth() - Auth failed, returning false');
    return false;
  }

  /// Guard for async operations - checks auth before executing action
  static Future<T?> guardAction<T>(
    BuildContext context,
    Future<T> Function() action, {
    String? errorMessage,
  }) async {
    if (!_isLoggedIn) {
      final authenticated = await requireAuth(context);
      if (!authenticated) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage ?? 'Authentication required'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
        return null;
      }
    }

    try {
      return await action();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return null;
    }
  }
}

/// Internal dialog widget for login/register flow
class _AuthDialog extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const _AuthDialog({
    Key? key,
    required this.onAuthSuccess,
  }) : super(key: key);

  @override
  State<_AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<_AuthDialog> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.maxFinite,
        child: _showLogin
            ? LoginScreen(
                onLoginSuccess: () {
                  widget.onAuthSuccess();
                },
                onRegisterPressed: () {
                  setState(() {
                    _showLogin = false;
                  });
                },
              )
            : RegisterScreen(
                onRegisterSuccess: () {
                  widget.onAuthSuccess();
                },
                onLoginPressed: () {
                  setState(() {
                    _showLogin = true;
                  });
                },
              ),
      ),
    );
  }
}
