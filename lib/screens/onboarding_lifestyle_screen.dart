import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/gradient_wrapper.dart';
import '../utils/auth_guard.dart';
import '../services/supabase_preferences_manager.dart' as preferences;

class OnboardingLifestyleScreen extends StatefulWidget {
  const OnboardingLifestyleScreen({super.key});

  @override
  State<OnboardingLifestyleScreen> createState() => _OnboardingLifestyleScreenState();
}

class _OnboardingLifestyleScreenState extends State<OnboardingLifestyleScreen> {
  bool _nutrition = false;
  bool _fitness = false;
  bool _fasting = false;
  bool _mood = false;
  bool _wellness = false;
  bool _agreedToPrivacy = false;

  final List<_LifestyleOption> _options = [
    _LifestyleOption(
      key: 'lifestyle_nutrition',
      title: 'Nutrition',
      emoji: '🍎',
      description: 'Get meal ideas that match your cycle phases',
      color: Colors.orange,
    ),
    _LifestyleOption(
      key: 'lifestyle_fitness',
      title: 'Fitness',
      emoji: '💪',
      description: 'Choose workouts that match your energy levels',
      color: Colors.blue,
    ),
    _LifestyleOption(
      key: 'lifestyle_fasting',
      title: 'Fasting',
      emoji: '⏱️',
      description: 'Optimize fasting windows for your cycle phases',
      color: Colors.purple,
    ),
    _LifestyleOption(
      key: 'lifestyle_mood',
      title: 'Mood & Productivity',
      emoji: '😊',
      description: 'Understand your mood patterns throughout your cycle',
      color: Colors.pink,
    ),
    _LifestyleOption(
      key: 'lifestyle_wellness',
      title: 'Wellness',
      emoji: '🌙',
      description: 'Sleep and stress tips for each phase',
      color: Colors.indigo,
    ),
  ];

  bool _isSelected(String key) {
    switch (key) {
      case 'lifestyle_nutrition':
        return _nutrition;
      case 'lifestyle_fitness':
        return _fitness;
      case 'lifestyle_fasting':
        return _fasting;
      case 'lifestyle_mood':
        return _mood;
      case 'lifestyle_wellness':
        return _wellness;
      default:
        return false;
    }
  }

  void _toggleOption(String key) {
    setState(() {
      switch (key) {
        case 'lifestyle_nutrition':
          _nutrition = !_nutrition;
          break;
        case 'lifestyle_fitness':
          _fitness = !_fitness;
          break;
        case 'lifestyle_fasting':
          _fasting = !_fasting;
          break;
        case 'lifestyle_mood':
          _mood = !_mood;
          break;
        case 'lifestyle_wellness':
          _wellness = !_wellness;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int selectedCount = [_nutrition, _fitness, _fasting, _mood, _wellness]
        .where((e) => e)
        .length;

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
                    const SizedBox(height: 12),
                    Text(
                      'Select what you\'d like to track. You can always add or remove these later.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _options.length,
                      itemBuilder: (context, index) {
                        final option = _options[index];
                        final isSelected = _isSelected(option.key);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GestureDetector(
                            onTap: () => _toggleOption(option.key),
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? option.color.withValues(alpha: 0.1)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? option.color
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    option.emoji,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          option.description,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF999999),
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? option.color : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected ? option.color : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        selectedCount == 0
                            ? 'Select at least one category to get started'
                            : 'You\'ve selected $selectedCount category${selectedCount > 1 ? 'ies' : ''}. You can change this anytime.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade900,
                          height: 1.5,
                        ),
                      ),
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
                      onPressed: (_agreedToPrivacy && selectedCount > 0)
                          ? () async {
                              // Check auth
                              if (!AuthGuard.isLoggedIn()) {
                                final authenticated = await AuthGuard.requireAuth(context);
                                if (!authenticated) return;
                              }

                              try {
                                final userId = AuthGuard.getCurrentUserId()!;

                                // Save to local storage
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setBool('lifestyle_nutrition', _nutrition);
                                await prefs.setBool('lifestyle_fitness', _fitness);
                                await prefs.setBool('lifestyle_fasting', _fasting);
                                await prefs.setBool('lifestyle_mood', _mood);
                                await prefs.setBool('lifestyle_wellness', _wellness);

                                // Save to Supabase
                                await preferences.SupabasePreferencesManager.updateUserPreferences(
                                  userId: userId,
                                  theme: 'light',
                                  notificationsEnabled: true,
                                );

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Preferences saved!'),
                                      backgroundColor: Color(0xFF4CAF50),
                                    ),
                                  );
                                  Navigator.of(context).pushReplacementNamed('/home');
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('❌ Error: $e'),
                                      backgroundColor: Color(0xFFDD4444),
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: const Color(0xFF333333),
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFF333333), width: 1.5),
                        disabledBackgroundColor: Colors.transparent,
                        disabledForegroundColor: const Color(0xFFCCCCCC),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Start Tracking',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
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

class _LifestyleOption {
  final String key;
  final String title;
  final String emoji;
  final String description;
  final Color color;

  _LifestyleOption({
    required this.key,
    required this.title,
    required this.emoji,
    required this.description,
    required this.color,
  });
}