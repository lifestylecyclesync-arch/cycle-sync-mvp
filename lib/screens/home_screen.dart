import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'favorites_database_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      const CalendarScreen(),
      const FavoritesDatabaseScreen(),
    ];
  }

  void _showAddPeriodDialog() {
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
                  // Refresh screens
                  setState(() {
                    _screens = [
                      const DashboardScreen(),
                      const CalendarScreen(),
                    ];
                  });
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
      body: Stack(
        children: [
          _screens[_selectedIndex],
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month),
                  label: 'Calendar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.collections_bookmark),
                  label: 'My Database',
                ),
              ],
              selectedItemColor: const Color(0xFF333333),
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.white,
              elevation: 10,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPeriodDialog,
        backgroundColor: Colors.pink.shade300,
        child: const Icon(Icons.add),
      ),
    );
  }
}
