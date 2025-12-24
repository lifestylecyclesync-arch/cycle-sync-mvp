import 'package:flutter/material.dart';
import 'screens/onboarding_welcome_screen.dart';
import 'screens/onboarding_cycle_input_screen.dart';
import 'screens/onboarding_lifestyle_screen.dart';
import 'screens/main_navigation.dart';
import 'utils/auth_guard.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase (only once here)
  await SupabaseService.initialize();
  
  // Initialize auth state
  await AuthGuard.initialize();
  
  runApp(const CycleSyncApp());
}

class CycleSyncApp extends StatelessWidget {
  const CycleSyncApp({super.key});

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