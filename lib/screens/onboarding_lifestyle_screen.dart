import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/gradient_wrapper.dart';

class OnboardingLifestyleScreen extends StatefulWidget {
  const OnboardingLifestyleScreen({super.key});

  @override
  State<OnboardingLifestyleScreen> createState() => _OnboardingLifestyleScreenState();
}

class _OnboardingLifestyleScreenState extends State<OnboardingLifestyleScreen> {
  bool _nutrition = false;
  bool _fitness = false;
  bool _mood = false;
  bool _wellness = false;
  bool _agreedToPrivacy = false;

  @override
  Widget build(BuildContext context) {
    return GradientWrapper(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync your lifestyle with your cycle',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                    ),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      title: const Text('🍎 Nutrition'),
                      subtitle: const Text('Food suggestions per phase'),
                      value: _nutrition,
                      onChanged: (val) {
                        setState(() {
                          _nutrition = val ?? false;
                        });
                      },
                      activeColor: const Color(0xFF333333),
                      checkColor: Colors.white,
                    ),
                    CheckboxListTile(
                      title: const Text('🏋️ Fitness'),
                      subtitle: const Text('Workouts matched to your energy'),
                      value: _fitness,
                      onChanged: (val) {
                        setState(() {
                          _fitness = val ?? false;
                        });
                      },
                      activeColor: const Color(0xFF333333),
                      checkColor: Colors.white,
                    ),
                    CheckboxListTile(
                      title: const Text('😊 Mood & Productivity'),
                      subtitle: const Text('Tips for focus and creativity'),
                      value: _mood,
                      onChanged: (val) {
                        setState(() {
                          _mood = val ?? false;
                        });
                      },
                      activeColor: const Color(0xFF333333),
                      checkColor: Colors.white,
                    ),
                    CheckboxListTile(
                      title: const Text('🌙 Wellness Basics'),
                      subtitle: const Text('Sleep and stress balance'),
                      value: _wellness,
                      onChanged: (val) {
                        setState(() {
                          _wellness = val ?? false;
                        });
                      },
                      activeColor: const Color(0xFF333333),
                      checkColor: Colors.white,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _agreedToPrivacy,
                        onChanged: (val) {
                          setState(() {
                            _agreedToPrivacy = val ?? false;
                          });
                        },
                        activeColor: const Color(0xFF333333),
                        checkColor: Colors.white,
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'I agree to the processing of my data ',
                            children: [
                              TextSpan(
                                text: 'according to the Privacy Policy',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _agreedToPrivacy
                          ? () async {
                              // Save lifestyle preferences to SharedPreferences
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('lifestyle_nutrition', _nutrition);
                              await prefs.setBool('lifestyle_fitness', _fitness);
                              await prefs.setBool('lifestyle_mood', _mood);
                              await prefs.setBool('lifestyle_wellness', _wellness);
                              if (mounted) {
                                Navigator.of(context).pushReplacementNamed('/dashboard');
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: const Color(0xFF333333),
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFF333333), width: 1.5),
                        disabledBackgroundColor: Colors.transparent,
                      ),
                      child: const Text('Finish Setup'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}