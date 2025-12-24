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
    _isLoggedIn = await UserManager.isLoggedIn();
    if (_isLoggedIn) {
      _currentUserId = await UserManager.getCurrentUserId();
    }
  }

  /// Update logout state
  static void logout() {
    _isLoggedIn = false;
    _currentUserId = null;
  }

  /// Show login/register dialog overlay
  static Future<bool> requireAuth(BuildContext context) async {
    if (_isLoggedIn) {
      return true; // Already logged in
    }

    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AuthDialog(
        onAuthSuccess: () {
          Navigator.pop(context, true);
        },
      ),
    );

    if (result == true) {
      await updateLoginState();
      return _isLoggedIn;
    }

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
