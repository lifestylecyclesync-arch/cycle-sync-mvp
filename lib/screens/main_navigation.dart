import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/cycle_fab.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'insights_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleLogSymptoms() {
    // Navigate to Calendar screen to open the symptoms logging
    // The calendar screen has the full Daily Details modal with symptoms & notes
    _pageController.animateToPage(
      1, // Calendar index
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _selectedIndex = 1;
    });

    // Show a snackbar to guide user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📝 Tap today\'s date to log symptoms & notes'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _handleAddGoal() {
    // Navigate to Profile screen with add goal dialog
    _pageController.animateToPage(
      2, // Profile index
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _selectedIndex = 2;
    });

    // Delay slightly to let navigation complete, then show snackbar
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('➕ Tap "Add Goal" in the Profile section'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _handleLogPeriod() {
    DateTime selectedDate = DateTime.now();
    int selectedCycleLength = 28;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('📍 Set Period Start'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'When did your last period start?',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 90)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade100,
                  foregroundColor: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              // Cycle length selector
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Cycle Length:',
                  style: TextStyle(fontSize: 12, color: Color(0xFF999999), fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<int>(
                  value: selectedCycleLength,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: List.generate(
                    17,
                    (i) => DropdownMenuItem(
                      value: 21 + i,
                      child: Text('${21 + i} days'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedCycleLength = value);
                    }
                  },
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
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('lastPeriodStart', selectedDate.toIso8601String());
                await prefs.setInt('cycleLength', selectedCycleLength);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Period start updated! (${selectedCycleLength} day cycle)')),
                  );
                }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [
          DashboardScreen(),
          CalendarScreen(),
          InsightsScreen(),
          ProfileScreen(),
        ],
      ),
      floatingActionButton: CycleFAB(
        onLogPeriod: _handleLogPeriod,
        onLogSymptoms: _handleLogSymptoms,
        onAddGoal: _handleAddGoal,
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard, 'Dashboard'),
              _buildNavItem(1, Icons.calendar_month, 'Calendar'),
              const SizedBox(width: 60), // Space for FAB
              _buildNavItem(2, Icons.insights, 'Insights'),
              _buildNavItem(3, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => _onNavBarTapped(index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.blue : Colors.grey.shade400,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.blue : Colors.grey.shade400,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
