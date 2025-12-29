import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/avatar_manager.dart';
import '../utils/goal_manager.dart' as util_goal;
import '../utils/auth_guard.dart';
import '../services/supabase_preferences_manager.dart' as preferences;
import '../services/supabase_goal_manager.dart' as supabase_goal;
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool openGoalDialog;
  
  const ProfileScreen({super.key, this.openGoalDialog = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  AvatarOption? _selectedAvatar;
  late TextEditingController _userNameController;
  List<String> _userSymptoms = [];
  
  // Collapsible sections state
  bool _expandedCycleInfo = true;
  bool _expandedPreferences = true;
  bool _expandedCompleteSetup = false;
  
  // Cycle data
  late DateTime _lastPeriodStart;
  late int _cycleLength;
  late int _periodLength;

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController();
    _loadUserData();
    
    if (widget.openGoalDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCreateGoalDialog();
      });
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    super.dispose();
  }

  /// Load all user data including cycle info
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final symptomsJson = prefs.getString('userSymptoms');
    
    String? lastPeriodStr = prefs.getString('lastPeriodStart');
    _lastPeriodStart = lastPeriodStr != null
        ? DateTime.parse(lastPeriodStr)
        : DateTime(2024, 11, 28);

    _cycleLength = prefs.getInt('cycleLength') ?? 28;
    _periodLength = prefs.getInt('periodLength') ?? 5;
    
    setState(() {
      _userName = prefs.getString('userName') ?? '';
      _userNameController.text = _userName;
      
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

  /// Save user data to local and Supabase
  Future<void> _saveUserData() async {
    // Check auth before saving
    if (!AuthGuard.isLoggedIn()) {
      final authenticated = await AuthGuard.requireAuth(context);
      if (!authenticated) return;
    }

    try {
      final userId = AuthGuard.getCurrentUserId()!;
      
      // Format name: capitalize first letter, rest lowercase
      final formattedName = _userName.isEmpty 
          ? '' 
          : _userName[0].toUpperCase() + _userName.substring(1).toLowerCase();

      // Save to Supabase
      await preferences.SupabasePreferencesManager.setAvatar(userId, _selectedAvatar?.id ?? 'default');

      // Also save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', formattedName);
      setState(() => _userName = formattedName);
      _userNameController.text = formattedName;
      await prefs.setString('userSymptoms', _userSymptoms.join(','));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Color(0xFFDD4444),
          ),
        );
      }
    }
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
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF333333),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
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
              const SizedBox(height: 30),

              // MY DATA SECTION - Collapsible cards
              Text(
                'My Data',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),

              // Cycle Info Card
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                child: ExpansionTile(
                  initiallyExpanded: _expandedCycleInfo,
                  onExpansionChanged: (expanded) {
                    setState(() => _expandedCycleInfo = expanded);
                  },
                  title: const Text(
                    'Cycle Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Cycle Length:', '$_cycleLength days'),
                          const SizedBox(height: 12),
                          _buildInfoRow('Period Length:', '$_periodLength days'),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Last Period Start:',
                            _lastPeriodStart.toLocal().toString().split(' ')[0],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/onboarding-cycle');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                              ),
                              child: const Text('Update Cycle Info'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Preferences Card
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                child: ExpansionTile(
                  initiallyExpanded: _expandedPreferences,
                  onExpansionChanged: (expanded) {
                    setState(() => _expandedPreferences = expanded);
                  },
                  title: const Text(
                    'Lifestyle Preferences',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Track your lifestyle preferences:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPreferenceItem('🍎 Nutrition'),
                                const SizedBox(height: 8),
                                _buildPreferenceItem('🏋️ Fitness'),
                                const SizedBox(height: 8),
                                _buildPreferenceItem('⏱️ Fasting'),
                                const SizedBox(height: 8),
                                _buildPreferenceItem('😊 Mood & Productivity'),
                                const SizedBox(height: 8),
                                _buildPreferenceItem('🌙 Wellness'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/lifestyle-preferences');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                              ),
                              child: const Text('Manage Preferences'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Complete Setup Card (if applicable)
              Card(
                elevation: 0,
                color: Colors.amber.shade50,
                child: ExpansionTile(
                  initiallyExpanded: _expandedCompleteSetup,
                  onExpansionChanged: (expanded) {
                    setState(() => _expandedCompleteSetup = expanded);
                  },
                  title: const Text(
                    '✓ Complete Your Setup',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Steps to complete your onboarding:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSetupStep('1', 'Update Your Cycle Information'),
                          const SizedBox(height: 8),
                          _buildSetupStep('2', 'Set Your Lifestyle Preferences'),
                          const SizedBox(height: 8),
                          _buildSetupStep('3', 'Select Symptoms to Track'),
                          const SizedBox(height: 8),
                          _buildSetupStep('4', 'Create Your First Goal'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF999999),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceItem(String label) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF333333),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSetupStep(String number, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.amber.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
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

  /// Show goal details dialog
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
                    // Check auth before saving
                    if (!AuthGuard.isLoggedIn()) {
                      final authenticated = await AuthGuard.requireAuth(context);
                      if (!authenticated) return;
                    }

                    try {
                      final userId = AuthGuard.getCurrentUserId()!;
                      
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
                        // Create goal object for local storage
                        final localGoal = util_goal.Goal(
                          id: util_goal.GoalManager.generateId(),
                          name: '${selectedType[0].toUpperCase()}${selectedType.substring(1)}',
                          type: selectedType,
                          frequency: selectedFrequency,
                          frequencyValue: frequencyValue,
                          amount: amount,
                          description: description,
                        );
                        
                        // Save to local storage
                        await util_goal.GoalManager.addGoal(localGoal);
                        
                        // Create and save to Supabase
                        final supabaseGoal = supabase_goal.Goal(
                          id: localGoal.id,
                          userId: userId,
                          goalType: _mapGoalTypeToEnum(selectedType),
                          targetValue: amount,
                          frequency: selectedFrequency,
                          description: description.isEmpty ? null : description,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        
                        await supabase_goal.SupabaseGoalManager.addGoal(supabaseGoal);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Goal saved!'),
                              backgroundColor: Color(0xFF4CAF50),
                            ),
                          );

                          if (widget.openGoalDialog) {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          } else {
                            Navigator.pop(context);
                          }
                        }
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

  /// Map goal type string to SupabaseGoalManager.GoalType enum
  supabase_goal.GoalType _mapGoalTypeToEnum(String type) {
    switch (type.toLowerCase()) {
      case 'exercise':
      case 'fitness':
        return supabase_goal.GoalType.fitness;
      case 'water':
      case 'hydration':
        return supabase_goal.GoalType.hydration;
      case 'sleep':
        return supabase_goal.GoalType.sleep;
      case 'meditation':
        return supabase_goal.GoalType.meditation;
      case 'nutrition':
        return supabase_goal.GoalType.nutrition;
      case 'wellness':
      case 'weightloss':
      default:
        return supabase_goal.GoalType.wellness;
    }
  }
}
