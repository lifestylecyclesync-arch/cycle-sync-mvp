import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/gradient_wrapper.dart';
import '../utils/favorites_manager.dart';

class FastingSuggestionsScreen extends StatefulWidget {
  final String fastingType;
  final String phase;
  final DateTime date;

  const FastingSuggestionsScreen({
    super.key,
    required this.fastingType,
    required this.phase,
    required this.date,
  });

  @override
  State<FastingSuggestionsScreen> createState() => _FastingSuggestionsScreenState();
}

class _FastingSuggestionsScreenState extends State<FastingSuggestionsScreen> {
  late Map<String, List<String>> _fastingOptions;
  String? _selectedFasting;
  List<String> _customFastingOptions = [];
  Set<String> _favoriteFasting = {};

  @override
  void initState() {
    super.initState();
    _loadFastingOptions();
    _loadSelectedFasting();
    _loadCustomFastingOptions();
    _loadFavoriteFasting();
  }

  Future<void> _loadFavoriteFasting() async {
    final favorites = await FavoritesManager.getFavoriteFasting();
    setState(() {
      _favoriteFasting = favorites;
    });
  }

  Future<void> _loadCustomFastingOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final customStr = prefs.getString('custom_fasting');
    setState(() {
      _customFastingOptions = customStr?.split(',').where((item) => item.isNotEmpty).toList() ?? [];
    });
  }

  Future<void> _addCustomFastingOption(String option) async {
    if (option.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (!_customFastingOptions.contains(option)) {
      _customFastingOptions.add(option);
      await prefs.setString('custom_fasting', _customFastingOptions.join(','));
      setState(() {});
    }
  }

  void _showAddCustomFastingDialog() {
    String customName = '';
    int selectedHours = 14;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Custom Fasting Window'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g., Morning fast, OMAD',
                  labelText: 'Name (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (value) => customName = value,
              ),
              const SizedBox(height: 20),
              Text(
                'Duration: $selectedHours hours',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              Slider(
                value: selectedHours.toDouble(),
                min: 8,
                max: 36,
                divisions: 28,
                onChanged: (value) {
                  setState(() => selectedHours = value.toInt());
                },
                activeColor: Colors.blue.shade400,
                label: '$selectedHours h',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  customName.isEmpty
                      ? '$selectedHours-hour fast'
                      : '$customName ($selectedHours-hour fast)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final fastingLabel = customName.isEmpty
                    ? '$selectedHours-hour fast'
                    : '$customName ($selectedHours-hour fast)';
                _addCustomFastingOption(fastingLabel);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade400,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _loadFastingOptions() {
    _fastingOptions = {
      'Power Fasting': [
        '16-hour fast (e.g., 4 PM - 8 AM)',
        '18-hour fast (e.g., 2 PM - 8 AM)',
        '20-hour fast (e.g., 12 PM - 8 AM)',
        'Flexible eating window with extended fasting',
      ],
      'Manifestation Fasting': [
        '24-hour water fast (one meal to one meal)',
        '36-hour extended fast',
        'Peak metabolic capacity window',
        'Water fasting optimal',
      ],
      'Nurture Fasting': [
        'Eat normally throughout the day',
        'No fasting period',
        'Regular meal schedule',
        'Focus on nutrient-dense foods',
      ],
    };
  }

  Future<void> _loadSelectedFasting() async {
    final prefs = await SharedPreferences.getInstance();
    String dateKey = 'fasting_${widget.date.toIso8601String().split('T')[0]}';
    final selected = prefs.getString(dateKey);
    setState(() {
      _selectedFasting = selected;
    });
  }

  Future<void> _saveFasting(String fasting) async {
    final prefs = await SharedPreferences.getInstance();
    String dateKey = 'fasting_${widget.date.toIso8601String().split('T')[0]}';
    await prefs.setString(dateKey, fasting);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fasting saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> suggestions = (_fastingOptions[widget.fastingType] ?? [])
        .where((fasting) => !_favoriteFasting.contains(fasting))
        .toList();
    List<String> allFastingOptions = [..._favoriteFasting.toList(), ..._customFastingOptions, ...suggestions];

    return GradientWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Standardized Header with Fasting Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.withValues(alpha: 0.3),
                      Colors.blue.withValues(alpha: 0.15),
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
                          '⏱️ ${widget.fastingType}',
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
                  itemCount: (_favoriteFasting.isNotEmpty ? 1 : 0) + allFastingOptions.length + 1,
                  itemBuilder: (context, index) {
                    // Favorites header
                    if (_favoriteFasting.isNotEmpty && index == 0) {
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

                    int adjustedIndex = _favoriteFasting.isNotEmpty ? index - 1 : index;

                    // Custom and suggested fasting options
                    if (adjustedIndex < allFastingOptions.length) {
                      String fasting = allFastingOptions[adjustedIndex];
                      bool isSelected = _selectedFasting == fasting;
                      bool isCustom = _customFastingOptions.contains(fasting);
                      bool isFavorited = _favoriteFasting.contains(fasting);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFasting = fasting;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.shade100 : Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.blue.withValues(alpha: 0.2),
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
                                      if (isCustom || isFavorited)
                                        Row(
                                          children: [
                                            if (isCustom)
                                              Text(
                                                'Custom',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue.shade600,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            if (isCustom && isFavorited) const SizedBox(width: 8),
                                          ],
                                        ),
                                      Text(
                                        fasting,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          color: const Color(0xFF333333),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        FavoritesManager.toggleFavoriteFasting(fasting);
                                        setState(() {
                                          if (_favoriteFasting.contains(fasting)) {
                                            _favoriteFasting.remove(fasting);
                                          } else {
                                            _favoriteFasting.add(fasting);
                                          }
                                        });
                                      },
                                      child: Icon(
                                        _favoriteFasting.contains(fasting) ? Icons.favorite : Icons.favorite_border,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
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
                    }

                    // Add button
                    if (adjustedIndex == allFastingOptions.length) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GestureDetector(
                          onTap: _showAddCustomFastingDialog,
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade300, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, color: Colors.blue.shade600),
                                const SizedBox(width: 12),
                                Text(
                                  'Add Custom Fasting',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // Fallback
                    return const SizedBox.shrink();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedFasting != null ? () => _saveFasting(_selectedFasting!) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFF333333),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFF333333), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: const Color(0xFFCCCCCC),
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
