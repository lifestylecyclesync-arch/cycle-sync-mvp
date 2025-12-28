import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/gradient_wrapper.dart';

class LifestylePreferencesScreen extends StatefulWidget {
  const LifestylePreferencesScreen({super.key});

  @override
  State<LifestylePreferencesScreen> createState() => _LifestylePreferencesScreenState();
}

class _LifestylePreferencesScreenState extends State<LifestylePreferencesScreen> {
  bool _nutrition = false;
  bool _fitness = false;
  bool _fasting = false;
  bool _mood = false;
  bool _wellness = false;
  bool _isLoading = true;

  final List<_PreferenceItem> _preferences = [
    _PreferenceItem(
      key: 'lifestyle_nutrition',
      title: 'Nutrition',
      emoji: '🍎',
      description: 'Personalized meal recommendations based on your cycle phase',
      color: Colors.orange,
    ),
    _PreferenceItem(
      key: 'lifestyle_fitness',
      title: 'Fitness',
      emoji: '💪',
      description: 'Workout suggestions tailored to your energy levels',
      color: Colors.blue,
    ),
    _PreferenceItem(
      key: 'lifestyle_fasting',
      title: 'Fasting',
      emoji: '⏱️',
      description: 'Fasting windows optimized for your cycle',
      color: Colors.purple,
    ),
    _PreferenceItem(
      key: 'lifestyle_mood',
      title: 'Mood & Productivity',
      emoji: '😊',
      description: 'Energy and mood insights throughout your cycle',
      color: Colors.pink,
    ),
    _PreferenceItem(
      key: 'lifestyle_wellness',
      title: 'Wellness',
      emoji: '🌙',
      description: 'Sleep and recovery recommendations',
      color: Colors.indigo,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nutrition = prefs.getBool('lifestyle_nutrition') ?? false;
      _fitness = prefs.getBool('lifestyle_fitness') ?? false;
      _fasting = prefs.getBool('lifestyle_fasting') ?? false;
      _mood = prefs.getBool('lifestyle_mood') ?? false;
      _wellness = prefs.getBool('lifestyle_wellness') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _togglePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    setState(() {
      if (key == 'lifestyle_nutrition') _nutrition = value;
      if (key == 'lifestyle_fitness') _fitness = value;
      if (key == 'lifestyle_fasting') _fasting = value;
      if (key == 'lifestyle_mood') _mood = value;
      if (key == 'lifestyle_wellness') _wellness = value;
    });
  }

  bool _isEnabled(String key) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return GradientWrapper(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    int enabledCount = [_nutrition, _fitness, _fasting, _mood, _wellness]
        .where((e) => e)
        .length;

    return GradientWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xFF333333),
          title: const Text('Track More Stuff'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    'Add more lifestyle tracking to personalize your plan. You\'ve enabled $enabledCount out of 5 categories.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade900,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: _preferences.length,
                    itemBuilder: (context, index) {
                      final pref = _preferences[index];
                      final isEnabled = _isEnabled(pref.key);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: isEnabled
                                ? pref.color.withValues(alpha: 0.1)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isEnabled
                                  ? pref.color
                                  : Colors.grey.shade300,
                              width: isEnabled ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(pref.emoji, style: const TextStyle(fontSize: 32)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pref.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF333333),
                                        decoration: isEnabled
                                            ? TextDecoration.none
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      pref.description,
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
                              Switch(
                                value: isEnabled,
                                onChanged: (value) {
                                  _togglePreference(pref.key, value);
                                },
                                activeThumbColor: pref.color,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true); // Return true to indicate preferences changed
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

class _PreferenceItem {
  final String key;
  final String title;
  final String emoji;
  final String description;
  final Color color;

  _PreferenceItem({
    required this.key,
    required this.title,
    required this.emoji,
    required this.description,
    required this.color,
  });
}
