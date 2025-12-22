import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/gradient_wrapper.dart';
import '../utils/favorites_manager.dart';

class FitnessSuggestionsScreen extends StatefulWidget {
  final String workoutType;
  final String phase;
  final DateTime date;

  const FitnessSuggestionsScreen({
    super.key,
    required this.workoutType,
    required this.phase,
    required this.date,
  });

  @override
  State<FitnessSuggestionsScreen> createState() => _FitnessSuggestionsScreenState();
}

class _FitnessSuggestionsScreenState extends State<FitnessSuggestionsScreen> {
  late Map<String, List<String>> _workoutSuggestions;
  List<String> _customWorkouts = [];
  Set<String> _selectedWorkouts = {};
  Set<String> _favoriteWorkouts = {};

  @override
  void initState() {
    super.initState();
    _loadWorkoutSuggestions();
    _loadCustomWorkouts();
    _loadSelectedWorkouts();
    _loadFavoriteWorkouts();
  }

  Future<void> _loadFavoriteWorkouts() async {
    final favorites = await FavoritesManager.getFavoriteWorkouts();
    setState(() {
      _favoriteWorkouts = favorites;
    });
  }

  void _loadWorkoutSuggestions() {
    _workoutSuggestions = {
      'Low-Impact Training': [
        'Gentle Yoga',
        'Walking',
        'Pilates',
        'Stretching',
        'Swimming (easy pace)',
        'Tai Chi',
        'Restorative Dance',
      ],
      'Mid-Impact Training': [
        'Strength Training (light)',
        'Cycling',
        'Hiking',
        'HIIT (moderate)',
        'Dance Cardio',
        'CrossFit (scaled)',
        'Circuit Training',
      ],
      'Strength Training': [
        'Heavy Lifting',
        'Sprint Training',
        'High-Intensity HIIT',
        'CrossFit',
        'Bootcamp',
        'Competitive Sports',
        'Plyometrics',
      ],
      'Mid-Impact Training (Sustain)': [
        'Strength Training (moderate)',
        'Cycling',
        'Running (steady-state)',
        'Pilates Power',
        'Functional Training',
        'Group Fitness Classes',
        'Elliptical Training',
      ],
      'Mid- to Low-Impact Training': [
        'Gentle Strength Training',
        'Restorative Yoga',
        'Walking',
        'Swimming',
        'Cycling (easy pace)',
        'Pilates',
        'Barre Fitness',
      ],
    };
  }

  Future<void> _loadCustomWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final customJson = prefs.getString('custom_workouts');
    setState(() {
      if (customJson != null && customJson.isNotEmpty) {
        _customWorkouts = List<String>.from(
          customJson.split(',').where((item) => item.isNotEmpty)
        );
      } else {
        _customWorkouts = [];
      }
    });
  }

  Future<void> _addCustomWorkout(String workout) async {
    if (workout.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customWorkouts.add(workout.trim());
    });
    await prefs.setString('custom_workouts', _customWorkouts.join(','));
  }

  void _showAddCustomDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Workout'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter workout name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addCustomWorkout(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSelectedWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    String dateKey = 'fitness_${widget.date.toIso8601String().split('T')[0]}';
    final selectedJson = prefs.getString(dateKey);
    setState(() {
      if (selectedJson != null && selectedJson.isNotEmpty) {
        _selectedWorkouts = Set<String>.from(
          selectedJson.split(',').where((item) => item.isNotEmpty)
        );
      } else {
        _selectedWorkouts = {};
      }
    });
  }

  void _toggleWorkout(String workout) {
    setState(() {
      if (_selectedWorkouts.contains(workout)) {
        _selectedWorkouts.remove(workout);
      } else {
        _selectedWorkouts.add(workout);
      }
    });
  }

  Future<void> _saveWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    String dateKey = 'fitness_${widget.date.toIso8601String().split('T')[0]}';
    
    if (_selectedWorkouts.isEmpty) {
      await prefs.remove(dateKey);
    } else {
      await prefs.setString(dateKey, _selectedWorkouts.join(','));
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> suggestions = (_workoutSuggestions[widget.workoutType] ?? [])
        .where((workout) => !_favoriteWorkouts.contains(workout))
        .toList();
    List<String> allWorkouts = [..._favoriteWorkouts.toList(), ..._customWorkouts, ...suggestions];

    return GradientWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Standardized Header with Fitness Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.withValues(alpha: 0.3),
                      Colors.green.withValues(alpha: 0.15),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '🏋️ ${widget.workoutType}',
                          style: const TextStyle(
                            fontSize: 22,
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF333333)),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.phase,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: (_favoriteWorkouts.isNotEmpty ? 1 : 0) + allWorkouts.length + 1,
                  itemBuilder: (context, index) {
                    // Favorites header
                    if (_favoriteWorkouts.isNotEmpty && index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
                        child: Text(
                          '❤️ My Favorites',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      );
                    }

                    int adjustedIndex = _favoriteWorkouts.isNotEmpty ? index - 1 : index;

                    // Add custom button at the end
                    if (adjustedIndex == allWorkouts.length) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GestureDetector(
                          onTap: _showAddCustomDialog,
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.shade300,
                                width: 1.5,
                                style: BorderStyle.solid,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Add Custom Workout',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.blue,
                                  size: 26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    String workout = allWorkouts[adjustedIndex];
                    bool isCustom = adjustedIndex < (_favoriteWorkouts.length + _customWorkouts.length) && adjustedIndex >= _favoriteWorkouts.length;
                    bool isFavorited = _favoriteWorkouts.contains(workout);
                    bool isSelected = _selectedWorkouts.contains(workout);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GestureDetector(
                        onTap: () => _toggleWorkout(workout),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? Colors.green.shade100
                              : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                ? Colors.green.shade600
                                : Colors.grey.shade300,
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      workout,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected 
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                        color: const Color(0xFF333333),
                                      ),
                                    ),
                                    if (isCustom || isFavorited)
                                      Row(
                                        children: [
                                          if (isCustom)
                                            const Text(
                                              'Custom',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          if (isCustom && isFavorited) const SizedBox(width: 8),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      FavoritesManager.toggleFavoriteWorkout(workout);
                                      setState(() {
                                        if (_favoriteWorkouts.contains(workout)) {
                                          _favoriteWorkouts.remove(workout);
                                        } else {
                                          _favoriteWorkouts.add(workout);
                                        }
                                      });
                                    },
                                    child: Icon(
                                      _favoriteWorkouts.contains(workout) ? Icons.favorite : Icons.favorite_border,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 26,
                                    )
                                  else
                                    const Icon(
                                      Icons.radio_button_unchecked,
                                      color: Color(0xFF999999),
                                      size: 24,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _saveWorkouts(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFF333333),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFF333333), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
