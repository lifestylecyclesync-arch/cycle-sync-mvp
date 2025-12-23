import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/avatar_manager.dart';
import '../utils/goal_manager.dart';

class ProfileScreen extends StatefulWidget {
  final bool openGoalDialog;
  
  const ProfileScreen({super.key, this.openGoalDialog = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  bool _notificationsEnabled = true;
  bool _dataCollectionEnabled = true;
  List<Goal> _goals = [];
  AvatarOption? _selectedAvatar;
  late TextEditingController _userNameController;
  List<String> _symptoms = [
    'Cramps',
    'Headache',
    'Fatigue',
    'Bloating',
    'Mood swings',
    'Acne',
    'Back pain',
  ];
  List<String> _userSymptoms = [];

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController();
    _loadUserData();
    
    if (widget.openGoalDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEditGoalsDialog();
      });
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    super.dispose();
  }

  /// Load all user data including goals
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final symptomsJson = prefs.getString('userSymptoms');
    final goals = await GoalManager.getAllGoals();
    
    setState(() {
      _userName = prefs.getString('userName') ?? '';
      _userNameController.text = _userName;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _dataCollectionEnabled = prefs.getBool('dataCollectionEnabled') ?? true;
      _goals = goals;
      
      if (symptomsJson != null) {
        _userSymptoms = symptomsJson.split(',').where((s) => s.isNotEmpty).toList();
      }
    });
    
    // Load selected avatar
    final avatar = await AvatarManager.getSelectedAvatar();
    setState(() {
      _selectedAvatar = avatar;
    });
  }

  /// Load all goals (used for sync across screens)
  Future<void> _loadGoals() async {
    try {
      final goals = await GoalManager.getAllGoals();
      setState(() {
        _goals = goals;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goals not loaded. Tap to refresh.')),
        );
      }
    }
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    // Format name: capitalize first letter, rest lowercase
    final formattedName = _userName.isEmpty 
        ? '' 
        : _userName[0].toUpperCase() + _userName.substring(1).toLowerCase();
    await prefs.setString('userName', formattedName);
    setState(() => _userName = formattedName);
    _userNameController.text = formattedName;
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('dataCollectionEnabled', _dataCollectionEnabled);
    await prefs.setString('userSymptoms', _userSymptoms.join(','));
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  Color _getPastelColor(String initials) {
    final colors = [
      const Color(0xFFFFB3BA), // Pastel pink
      const Color(0xFFFFDFBA), // Pastel peach
      const Color(0xFFFFFABA), // Pastel yellow
      const Color(0xFFBAFFBA), // Pastel green
      const Color(0xFFBAE1FF), // Pastel blue
      const Color(0xFFE0BBE4), // Pastel purple
      const Color(0xFFFFBBE3), // Pastel magenta
    ];
    final hashCode = initials.hashCode;
    return colors[hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _userName.isEmpty ? 'Guest' : _userName;
    final initials = _getInitials(displayName);
    final pastelColor = _getPastelColor(initials);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF333333),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar Section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: _showAvatarSelectionDialog,
                  child: Column(
                    children: [
                      if (_selectedAvatar?.isPhoto == true && _selectedAvatar?.photoPath != null)
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: FileImage(File(_selectedAvatar!.photoPath!)),
                        )
                      else
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: _selectedAvatar?.color ?? pastelColor,
                          child: Text(
                            _selectedAvatar?.emoji ?? initials,
                            style: TextStyle(
                              fontSize: _selectedAvatar != null ? 40 : 36,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to change avatar',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.pink.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Profile Card
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF999999),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _userNameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          hintText: 'Guest',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() => _userName = value);
                          _saveUserData();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Goals Card
              // Goals Card
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '🎯 Your Goals',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                          if (_goals.isNotEmpty)
                            Text(
                              '${_goals.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.pink.shade400,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_goals.isEmpty)
                        const Text(
                          'No goals set yet. Tap + to add…',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF999999),
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ..._buildGroupedGoals(),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _showCreateGoalDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade400, width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, size: 14, color: Colors.green.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Add Goal',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Symptoms Card
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Symptoms to Track',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF999999),
                            ),
                          ),
                          GestureDetector(
                            onTap: _showEditSymptomsDialog,
                            child: Icon(Icons.edit, color: Colors.pink.shade400, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _userSymptoms.map((symptom) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.pink.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.pink.shade300),
                            ),
                            child: Text(
                              symptom,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_userSymptoms.isEmpty)
                        const Text(
                          'No symptoms selected. Add symptoms to track during your cycle.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Preferences Card
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preferences',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF999999),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildToggleTile(
                        'Notifications',
                        'Receive cycle reminders and tips',
                        _notificationsEnabled,
                        (value) {
                          setState(() => _notificationsEnabled = value);
                          _saveUserData();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildToggleTile(
                        'Data Collection',
                        'Help improve the app with anonymized insights',
                        _dataCollectionEnabled,
                        (value) {
                          setState(() => _dataCollectionEnabled = value);
                          _saveUserData();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Privacy Card
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Privacy & Security',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF999999),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoTile(
                        'Data Storage',
                        'All your data is stored locally on your device',
                        Icons.storage,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoTile(
                        'Privacy Policy',
                        'Learn how we protect your information',
                        Icons.description,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // About Section
              Center(
                child: Column(
                  children: [
                    Text(
                      'Cycle Sync MVP',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.pink.shade400,
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.pink.shade400,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, Map<String, dynamic>> _getGoalFieldConfig() {
    return {
      'exercise': {
        'requiresFrequency': true,
        'fields': [
          {'key': 'duration', 'label': 'Duration', 'hint': 'e.g., 30 minutes', 'type': 'text'},
          {'key': 'exerciseType', 'label': 'Type of Exercise', 'type': 'toggleList', 'options': ['Running', 'Yoga', 'Strength', 'Swimming', 'Cycling', 'Walking']},
        ],
      },
      'water': {
        'requiresFrequency': false,
        'fields': [
          {'key': 'amount', 'label': 'Amount per Day', 'hint': 'e.g., 2 liters, 8 glasses', 'type': 'text'},
          {'key': 'note', 'label': 'Note (optional)', 'hint': 'e.g., With lemon', 'type': 'text'},
        ],
      },
      'sleep': {
        'requiresFrequency': false,
        'fields': [
          {'key': 'hours', 'label': 'Hours per Night', 'hint': 'e.g., 8', 'type': 'text'},
          {'key': 'note', 'label': 'Note (optional)', 'hint': 'e.g., Before 10 PM', 'type': 'text'},
        ],
      },
      'meditation': {
        'requiresFrequency': true,
        'fields': [
          {'key': 'duration', 'label': 'Duration', 'hint': 'e.g., 10 minutes', 'type': 'text'},
          {'key': 'meditationType', 'label': 'Type', 'type': 'toggleList', 'options': ['Guided', 'Breathing', 'Body Scan', 'Visualization']},
          {'key': 'note', 'label': 'Note (optional)', 'hint': 'e.g., Morning meditation', 'type': 'text'},
        ],
      },
      'nutrition': {
        'requiresFrequency': false,
        'fields': [
          {'key': 'dietType', 'label': 'Diet Type', 'type': 'toggleListWithCustom', 'options': ['Low Carb', 'Keto', 'No Sugar', 'High Protein', 'Vegan', 'Balanced']},
          {'key': 'focusArea', 'label': 'Focus Area (optional)', 'hint': 'e.g., Vegetables, Proteins', 'type': 'text'},
        ],
      },
      'weightloss': {
        'requiresFrequency': false,
        'fields': [
          {'key': 'amount', 'label': 'Target Weight', 'hint': 'e.g., 5', 'type': 'text'},
          {'key': 'unit', 'label': 'Unit', 'type': 'toggleList', 'options': ['kg', 'lbs', 'stones', 'pounds']},
          {'key': 'timeRange', 'label': 'Time Range', 'hint': 'e.g., 3 months, 6 weeks', 'type': 'text'},
        ],
      },
      'wellness': {
        'requiresFrequency': true,
        'fields': [
          {'key': 'activity', 'label': 'Activity', 'hint': 'e.g., Cold shower, Journal', 'type': 'text'},
          {'key': 'duration', 'label': 'Duration/Details (optional)', 'hint': 'e.g., 5 minutes', 'type': 'text'},
        ],
      },
    };
  }

  void _showEditGoalDialog(Goal existingGoal) {
    // Parse the goal data to reconstruct the form state
    String selectedType = existingGoal.type;
    String selectedFrequency = existingGoal.frequency;
    int frequencyValue = existingGoal.frequencyValue;
    Map<String, String> fieldValues = {};
    Map<String, String> selectedToggles = {};

    // Parse description and amount to reconstruct field values
    final parts = <String>[];
    if (existingGoal.amount.isNotEmpty) {
      parts.add(existingGoal.amount);
    }
    if (existingGoal.description.isNotEmpty) {
      parts.addAll(existingGoal.description.split(', '));
    }

    // Get the field config for the goal type
    final fieldConfig = _getGoalFieldConfig();
    final goalConfig = fieldConfig[selectedType];
    
    if (goalConfig != null) {
      final fields = goalConfig['fields'] as List<Map<String, dynamic>>;
      
      // Try to match parts to fields
      int partIndex = 0;
      for (var field in fields) {
        if (partIndex >= parts.length) break;
        
        final key = field['key'] as String;
        final type = field['type'] as String;
        
        if (type == 'text') {
          fieldValues[key] = parts[partIndex];
          partIndex++;
        } else if (type == 'toggleList' || type == 'toggleListWithCustom') {
          final options = (field['options'] as List<String>?) ?? [];
          final part = parts[partIndex];
          if (options.contains(part)) {
            selectedToggles[key] = part;
            fieldValues[key] = part;
          } else {
            fieldValues[key] = part;
          }
          partIndex++;
        }
      }
    }

    final typeOptions = ['exercise', 'water', 'sleep', 'meditation', 'nutrition', 'weightloss', 'wellness'];
    final frequencyOptions = ['daily', 'weekly', 'monthly'];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final currentConfig = fieldConfig[selectedType]!;
          final fields = currentConfig['fields'] as List<Map<String, dynamic>>;
          final requiresFrequency = currentConfig['requiresFrequency'] as bool? ?? false;
          
          return AlertDialog(
            title: const Text('Edit Goal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Goal Type
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Goal Type',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          value: selectedType,
                          isExpanded: true,
                          items: typeOptions.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text('${type[0].toUpperCase()}${type.substring(1)}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedType = value ?? selectedType;
                              fieldValues.clear();
                              selectedToggles.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  // Frequency - only show if required for this goal type
                  if (requiresFrequency) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Frequency',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                          ),
                          const SizedBox(height: 8),
                          DropdownButton<String>(
                            value: selectedFrequency,
                            isExpanded: true,
                            items: frequencyOptions.map((freq) {
                              return DropdownMenuItem(
                                value: freq,
                                child: Text('${freq[0].toUpperCase()}${freq.substring(1)}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => selectedFrequency = value ?? selectedFrequency);
                            },
                          ),
                        ],
                      ),
                    ),
                    // Frequency Value - only show if frequency is required
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How many times per $selectedFrequency?',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: frequencyValue.toString()),
                            decoration: InputDecoration(
                              hintText: 'e.g., 3',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (value) {
                              setState(() => frequencyValue = int.tryParse(value) ?? 1);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Dynamic Fields
                  ...fields.map((field) {
                    final key = field['key'] as String;
                    final label = field['label'] as String;
                    final type = field['type'] as String;
                    final initialValue = fieldValues[key] ?? '';
                    
                    if (type == 'text') {
                      final hint = field['hint'] as String? ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: TextEditingController(text: initialValue),
                              decoration: InputDecoration(
                                hintText: hint,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (value) {
                                setState(() => fieldValues[key] = value);
                              },
                            ),
                          ],
                        ),
                      );
                    } else if (type == 'toggleList') {
                      final options = (field['options'] as List<String>?) ?? [];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: options.map((option) {
                                final isSelected = selectedToggles[key] == option;
                                return FilterChip(
                                  label: Text(option),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedToggles[key] = option;
                                        fieldValues[key] = option;
                                      } else {
                                        selectedToggles.remove(key);
                                        fieldValues.remove(key);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    } else if (type == 'toggleListWithCustom') {
                      final options = (field['options'] as List<String>?) ?? [];
                      final isCustom = !options.contains(initialValue);
                      final customValue = isCustom ? initialValue : '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...options.map((option) {
                                  final isSelected = selectedToggles[key] == option;
                                  return FilterChip(
                                    label: Text(option),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          selectedToggles[key] = option;
                                          fieldValues[key] = option;
                                        } else {
                                          selectedToggles.remove(key);
                                          fieldValues.remove(key);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: TextEditingController(text: customValue),
                              decoration: InputDecoration(
                                labelText: 'Or enter custom diet type',
                                hintText: 'e.g., Paleo, Mediterranean',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  if (value.isNotEmpty) {
                                    selectedToggles[key] = value;
                                    fieldValues[key] = value;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Build the amount and description from field values
                  String amount = '';
                  String description = '';
                  bool amountSet = false;
                  
                  for (var field in fields) {
                    final key = field['key'] as String;
                    final value = fieldValues[key] ?? '';
                    
                    if (value.isEmpty) continue;
                    
                    // First non-empty value becomes amount
                    if (!amountSet) {
                      amount = value;
                      amountSet = true;
                    } else {
                      // Everything else goes to description
                      description += (description.isEmpty ? '' : ', ') + value;
                    }
                  }
                  
                  if (amount.isNotEmpty) {
                    final updatedGoal = Goal(
                      id: existingGoal.id,
                      name: existingGoal.name,
                      type: selectedType,
                      frequency: selectedFrequency,
                      frequencyValue: frequencyValue,
                      amount: amount,
                      description: description,
                      completedDates: existingGoal.completedDates,
                    );
                    
                    await GoalManager.updateGoal(updatedGoal);
                    await _loadGoals(); // Sync across all screens
                    
                    // If opened from dashboard, pop to return to dashboard
                    if (widget.openGoalDialog) {
                      if (mounted) {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Return to dashboard
                      }
                    } else {
                      if (mounted) {
                        Navigator.pop(context); // Just close dialog
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade400,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Group goals by type for display
  Map<String, List<Goal>> _getGoalsByType() {
    final groupedGoals = <String, List<Goal>>{};
    for (final goal in _goals) {
      if (!groupedGoals.containsKey(goal.type)) {
        groupedGoals[goal.type] = [];
      }
      groupedGoals[goal.type]!.add(goal);
    }
    return groupedGoals;
  }

  /// Build grouped goal widgets
  List<Widget> _buildGroupedGoals() {
    final groupedGoals = _getGoalsByType();
    final List<Widget> widgets = [];

    for (final type in groupedGoals.keys) {
      final goals = groupedGoals[type]!;

      // Type header
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            _getGoalTypeLabel(type),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );

      // Goals in this type
      for (final goal in goals) {
        widgets.add(_buildGoalItem(goal));
      }

      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  /// Build individual goal item with shortcuts
  Widget _buildGoalItem(Goal goal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.pink.shade200),
        ),
        child: Row(
          children: [
            // Goal details (tappable for details view)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _showGoalDetailsDialog(goal);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal.getDisplayString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Edit button
            GestureDetector(
              onTap: () => _showEditGoalDialog(goal),
              child: Icon(
                Icons.edit,
                color: Colors.blue.shade400,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Delete button
            GestureDetector(
              onTap: () => _showDeleteGoalConfirm(goal.id),
              child: Icon(
                Icons.close,
                color: Colors.red.shade400,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get display label for goal type
  String _getGoalTypeLabel(String type) {
    final labels = {
      'exercise': '💪 Exercise',
      'water': '💧 Water',
      'sleep': '😴 Sleep',
      'meditation': '🧘 Meditation',
      'nutrition': '🥗 Nutrition',
      'weightloss': '⚖️ Weight Loss',
      'wellness': '✨ Wellness',
    };
    return labels[type] ?? type;
  }

  /// Show goal details dialog
  void _showGoalDetailsDialog(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(goal.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${_getGoalTypeLabel(goal.type)}'),
            if (goal.frequency.isNotEmpty) Text('Frequency: ${goal.frequency}'),
            if (goal.frequencyValue > 0) Text('Times per period: ${goal.frequencyValue}'),
            if (goal.amount.isNotEmpty) Text('Amount: ${goal.amount}'),
            if (goal.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Description: ${goal.description}'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditGoalDialog(goal);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showEditGoalsDialog() {
    _showCreateGoalDialog();
  }

  void _showCreateGoalDialog() {
    int currentStep = 0;
    String selectedType = 'exercise';
    String selectedFrequency = 'weekly';
    int frequencyValue = 3;
    Map<String, String> fieldValues = {};
    Map<String, String> selectedToggles = {};

    final typeOptions = ['exercise', 'water', 'sleep', 'meditation', 'nutrition', 'weightloss', 'wellness'];
    final frequencyOptions = ['daily', 'weekly', 'monthly'];
    final fieldConfig = _getGoalFieldConfig();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final currentConfig = fieldConfig[selectedType]!;
          final fields = currentConfig['fields'] as List<Map<String, dynamic>>;
          final requiresFrequency = currentConfig['requiresFrequency'] as bool? ?? false;
          
          // Determine total steps
          int totalSteps = 2; // Type + Details
          if (requiresFrequency) totalSteps = 3; // Type + Frequency + Details
          
          return AlertDialog(
            title: Text('Add New Goal (Step ${currentStep + 1}/$totalSteps)'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Step 1: Select Goal Type
                  if (currentStep == 0) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'What type of goal would you like to set?',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                          ),
                          const SizedBox(height: 16),
                          DropdownButton<String>(
                            value: selectedType,
                            isExpanded: true,
                            items: typeOptions.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text('${type[0].toUpperCase()}${type.substring(1)}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedType = value ?? selectedType;
                                fieldValues.clear();
                                selectedToggles.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Step 2: Select Frequency (if required)
                  if (requiresFrequency && currentStep == 1) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How often do you want to do this?',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                          ),
                          const SizedBox(height: 12),
                          DropdownButton<String>(
                            value: selectedFrequency,
                            isExpanded: true,
                            items: frequencyOptions.map((freq) {
                              return DropdownMenuItem(
                                value: freq,
                                child: Text('${freq[0].toUpperCase()}${freq.substring(1)}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => selectedFrequency = value ?? selectedFrequency);
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'How many times per $selectedFrequency?',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: frequencyValue.toString()),
                            decoration: InputDecoration(
                              hintText: 'e.g., 3',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (value) {
                              setState(() => frequencyValue = int.tryParse(value) ?? 1);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Final Step: Add Details
                  if (currentStep == (requiresFrequency ? 2 : 1)) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add details about your goal',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                          ),
                          const SizedBox(height: 16),
                          ...fields.map((field) {
                            final key = field['key'] as String;
                            final label = field['label'] as String;
                            final type = field['type'] as String;
                            
                            if (type == 'text') {
                              final hint = field['hint'] as String? ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      decoration: InputDecoration(
                                        hintText: hint,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onChanged: (value) {
                                        setState(() => fieldValues[key] = value);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            } else if (type == 'toggleList') {
                              final options = (field['options'] as List<String>?) ?? [];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: options.map((option) {
                                        final isSelected = selectedToggles[key] == option;
                                        return FilterChip(
                                          label: Text(option),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected) {
                                                selectedToggles[key] = option;
                                                fieldValues[key] = option;
                                              } else {
                                                selectedToggles.remove(key);
                                                fieldValues.remove(key);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              );
                            } else if (type == 'toggleListWithCustom') {
                              final options = (field['options'] as List<String>?) ?? [];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ...options.map((option) {
                                          final isSelected = selectedToggles[key] == option;
                                          return FilterChip(
                                            label: Text(option),
                                            selected: isSelected,
                                            onSelected: (selected) {
                                              setState(() {
                                                if (selected) {
                                                  selectedToggles[key] = option;
                                                  fieldValues[key] = option;
                                                } else {
                                                  selectedToggles.remove(key);
                                                  fieldValues.remove(key);
                                                }
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      decoration: InputDecoration(
                                        labelText: 'Or enter custom diet type',
                                        hintText: 'e.g., Paleo, Mediterranean',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          if (value.isNotEmpty) {
                                            selectedToggles[key] = value;
                                            fieldValues[key] = value;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }
                            return SizedBox.shrink();
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              if (currentStep > 0)
                TextButton(
                  onPressed: () {
                    setState(() => currentStep--);
                  },
                  child: const Text('Back'),
                ),
              if (currentStep < totalSteps - 1)
                ElevatedButton(
                  onPressed: () {
                    setState(() => currentStep++);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade400,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Next'),
                ),
              if (currentStep == totalSteps - 1)
                ElevatedButton(
                  onPressed: () async {
                    // Build the amount and description from field values
                    String amount = '';
                    String description = '';
                    bool amountSet = false;
                    
                    for (var field in fields) {
                      final key = field['key'] as String;
                      final value = fieldValues[key] ?? '';
                      
                      if (value.isEmpty) continue;
                      
                      if (!amountSet) {
                        amount = value;
                        amountSet = true;
                      } else {
                        description += (description.isEmpty ? '' : ', ') + value;
                      }
                    }
                    
                    if (amount.isNotEmpty) {
                      final newGoal = Goal(
                        id: GoalManager.generateId(),
                        name: '${selectedType[0].toUpperCase()}${selectedType.substring(1)}',
                        type: selectedType,
                        frequency: selectedFrequency,
                        frequencyValue: frequencyValue,
                        amount: amount,
                        description: description,
                      );
                      
                      await GoalManager.addGoal(newGoal);
                      await _loadGoals(); // Sync across all screens
                      
                      if (mounted) {
                        if (widget.openGoalDialog) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        } else {
                          Navigator.pop(context);
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade400,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Goal'),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeleteGoalConfirm(String goalId) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Goal?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'re about to delete:',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.pink.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  if (goal.amount.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        goal.amount,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone. All progress for this goal will be deleted.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await GoalManager.deleteGoal(goalId);
              await _loadGoals(); // Sync across all screens
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${goal.name} deleted'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.pink.shade400,
                  ),
                );
                Navigator.pop(context);
                
                // If opened from dashboard, also pop the profile screen to return to dashboard
                if (widget.openGoalDialog) {
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete Goal',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  void _showEditSymptomsDialog() {
    final selectedSymptoms = Set<String>.from(_userSymptoms);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Symptoms to Track'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _symptoms.map((symptom) {
                return CheckboxListTile(
                  title: Text(symptom),
                  value: selectedSymptoms.contains(symptom),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedSymptoms.add(symptom);
                      } else {
                        selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                this.setState(() {
                  _userSymptoms = selectedSymptoms.toList();
                });
                _saveUserData();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade400,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarSelectionDialog() {
    final imagePicker = ImagePicker();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Choose Your Avatar'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Upload Photo Button or Display Current Photo
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedAvatar?.isPhoto == true ? Colors.pink : Colors.grey.shade400,
                      width: _selectedAvatar?.isPhoto == true ? 3 : 2,
                      style: BorderStyle.solid,
                    ),
                    boxShadow: _selectedAvatar?.isPhoto == true
                        ? [
                            BoxShadow(
                              color: Colors.pink.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: _selectedAvatar?.isPhoto == true && _selectedAvatar?.photoPath != null
                        ? GestureDetector(
                            onTap: () async {
                              final pickedFile = await imagePicker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 512,
                                maxHeight: 512,
                              );
                              
                              if (pickedFile != null) {
                                final avatar = AvatarOption(
                                  id: 'photo_${DateTime.now().millisecondsSinceEpoch}',
                                  photoPath: pickedFile.path,
                                  label: 'My Photo',
                                  color: Colors.grey.shade200,
                                  isPhoto: true,
                                );
                                setState(() {
                                  _selectedAvatar = avatar;
                                });
                              }
                            },
                            child: CircleAvatar(
                              radius: 35,
                              backgroundImage: FileImage(File(_selectedAvatar!.photoPath!)),
                            ),
                          )
                        : InkWell(
                            onTap: () async {
                              final pickedFile = await imagePicker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 512,
                                maxHeight: 512,
                              );
                              
                              if (pickedFile != null) {
                                final avatar = AvatarOption(
                                  id: 'photo_${DateTime.now().millisecondsSinceEpoch}',
                                  photoPath: pickedFile.path,
                                  label: 'My Photo',
                                  color: Colors.grey.shade200,
                                  isPhoto: true,
                                );
                                setState(() {
                                  _selectedAvatar = avatar;
                                });
                              }
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  color: Colors.grey.shade600,
                                  size: 24,
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Add Photo',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF666666),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Preset Avatars',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AvatarManager.presetAvatars.map((avatar) {
                    final isSelected = _selectedAvatar?.id == avatar.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAvatar = avatar;
                        });
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: avatar.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.pink : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.pink.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              avatar.emoji ?? '🎨',
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              avatar.label,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_selectedAvatar != null) {
                  if (_selectedAvatar!.isPhoto) {
                    // Saving a photo avatar - clear the emoji ID
                    await AvatarManager.setPhotoAvatar(_selectedAvatar!.photoPath!);
                  } else {
                    // Saving an emoji avatar - clear the photo path
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('selectedPhotoPath');
                    await AvatarManager.setSelectedAvatar(_selectedAvatar!.id);
                  }
                  _saveUserData();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade300,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
