import 'package:flutter/material.dart';
import '../widgets/gradient_wrapper.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientWrapper(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                const Icon(
                  Icons.favorite_outline,
                  size: 80,
                  color: Color(0xFF333333),
                ),
                const SizedBox(height: 20),

                // Tagline
                Text(
                  'Sync your cycle.',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                ),
                Text(
                  'Sync your life.',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        fontSize: 28,
                      ),
                ),
                const SizedBox(height: 30),

                // Description
                Text(
                  'Track your cycle, understand your body, and live in sync with your natural rhythms.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                      ),
                ),
                const SizedBox(height: 50),

                // Primary Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/cycleBasics');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFF333333),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFF333333), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Start Tracking Your Cycle',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Secondary Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      // Learn more action
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF333333),
                    ),
                    child: Text(
                      'Learn More',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}