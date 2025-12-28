import 'package:flutter/material.dart';
import '../services/supabase_user_manager.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegisterSuccess;
  final VoidCallback? onLoginPressed;

  const RegisterScreen({
    Key? key,
    required this.onRegisterSuccess,
    this.onLoginPressed,
  }) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Email validation
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Email is required');
      return false;
    }
    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return false;
    }

    // Password validation
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Password is required');
      return false;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return false;
    }

    // Confirm password
    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return false;
    }

    // Terms agreement
    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'Please agree to the terms');
      return false;
    }

    return true;
  }

  Future<void> _handleRegister() async {
    if (!_validateInputs()) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      print('🔐 RegisterScreen._handleRegister() - Starting registration with email: ${_emailController.text.trim()}');
      final success = await UserManager.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      print('🔐 RegisterScreen._handleRegister() - Result: success=$success');
      if (success) {
        if (mounted) {
          print('🔐 RegisterScreen._handleRegister() - Calling onRegisterSuccess callback');
          widget.onRegisterSuccess();
        }
      } else {
        print('🔐 RegisterScreen._handleRegister() - Registration returned false');
        setState(() {
          _errorMessage = 'Registration failed. Email may already be in use.';
        });
      }
    } catch (e) {
      print('Register catch block - Error: $e');
      print('Register catch block - Error type: ${e.runtimeType}');
      setState(() {
        _errorMessage = 'Registration failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final success = await UserManager.signInWithGoogle();

      if (success) {
        if (mounted) {
          widget.onRegisterSuccess();
        }
      } else {
        setState(() {
          _errorMessage = 'Google sign up failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google sign up error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Title
              Text(
                'Join Cycle Sync',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Create an account to save your cycle data',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF666666),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'your@email.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              const SizedBox(height: 20),

              // Terms Agreement
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _agreedToTerms = value ?? false;
                              _errorMessage = null;
                            });
                          },
                  ),
                  Expanded(
                    child: Text(
                      'I agree to the Terms of Service and Privacy Policy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF666666),
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFF0E6FF),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Google Sign-In Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                  disabledBackgroundColor: Colors.grey.shade100,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/google_icon.png',
                            height: 20,
                            width: 20,
                            errorBuilder: (context, error, stackTrace) {
                              return const Text('G');
                            },
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Sign up with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  GestureDetector(
                    onTap: _isLoading ? null : widget.onLoginPressed,
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.purple.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
