import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'screens/onboarding_welcome_screen.dart';
import 'screens/onboarding_cycle_input_screen.dart';
import 'screens/onboarding_lifestyle_screen.dart';
import 'screens/main_navigation.dart';
import 'utils/auth_guard.dart';
import 'services/supabase_service.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase (only once here)
  await SupabaseService.initialize();
  
  // Initialize auth state
  await AuthGuard.initialize();
  
  runApp(const CycleSyncApp());
}

class CycleSyncApp extends StatefulWidget {
  const CycleSyncApp({super.key});

  @override
  State<CycleSyncApp> createState() => _CycleSyncAppState();
}

class _CycleSyncAppState extends State<CycleSyncApp> {
  late AppLinks _appLinks;
  late StreamSubscription<Uri> _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _handleDeepLink();
  }

  void _handleDeepLink() {
    // Handle subsequent deep links
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleLink(uri);
      },
      onError: (err) {
        print('🔗 Deep link error: $err');
      },
    );
  }

  void _handleLink(Uri uri) {
    print('🔗 Deep link received: $uri');
    print('🔗 Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
    print('🔗 Query parameters: ${uri.queryParameters}');
    
    // Handle password reset deep link
    if (uri.scheme == 'com.example.cycle_sync_mvp' && uri.host == 'auth') {
      // Extract tokens from the link
      final accessToken = uri.queryParameters['access_token'];
      final type = uri.queryParameters['type'];
      final expiresIn = uri.queryParameters['expires_in'];
      
      print('🔗 Access token: ${accessToken != null ? 'present' : 'missing'}, Type: $type, Expires in: $expiresIn');
      
      if (type == 'recovery' && accessToken != null) {
        // This is a password recovery link
        // Show password reset dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPasswordResetDialog(accessToken);
        });
      } else {
        print('🔗 Not a recovery type or missing access token');
      }
    } else {
      print('🔗 Deep link scheme/host mismatch. Expected: com.example.cycle_sync_mvp://auth');
    }
  }

  void _showPasswordResetDialog(String accessToken) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: const Text('Your password reset link was verified. You can now set a new password.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _deepLinkSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cycle Sync MVP',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        // Softer black text color
        textTheme: const TextTheme(
          bodySmall: TextStyle(color: Color(0xFF333333)),
          bodyMedium: TextStyle(color: Color(0xFF333333)),
          bodyLarge: TextStyle(color: Color(0xFF333333)),
          displaySmall: TextStyle(color: Color(0xFF333333)),
          displayMedium: TextStyle(color: Color(0xFF333333)),
          displayLarge: TextStyle(color: Color(0xFF333333)),
          headlineSmall: TextStyle(color: Color(0xFF333333)),
          headlineMedium: TextStyle(color: Color(0xFF333333)),
          headlineLarge: TextStyle(color: Color(0xFF333333)),
          labelSmall: TextStyle(color: Color(0xFF333333)),
          labelMedium: TextStyle(color: Color(0xFF333333)),
          labelLarge: TextStyle(color: Color(0xFF333333)),
          titleSmall: TextStyle(color: Color(0xFF333333)),
          titleMedium: TextStyle(color: Color(0xFF333333)),
          titleLarge: TextStyle(color: Color(0xFF333333)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF0E6FF), // Very light lavender
            foregroundColor: const Color(0xFF333333),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            side: const BorderSide(color: Color(0xFFD4C5F9), width: 1),
          ),
        ),
      ),
      home: const OnboardingWelcomeScreen(),
      routes: {
        '/cycleBasics': (context) => const OnboardingCycleInputScreen(),
        '/lifestylePreferences': (context) => const OnboardingLifestyleScreen(),
        '/home': (context) => const MainNavigation(),
      },
    );
  }
}