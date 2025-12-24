import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'insights_screen.dart';
import '../widgets/cycle_fab.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: const [
              DashboardScreen(),
              CalendarScreen(),
              ProfileScreen(),
              InsightsScreen(),
            ],
          ),
          // FAB overlaid on top of pages
          CycleFAB(
            onLogSymptoms: _handleLogSymptoms,
            onAddGoal: _handleAddGoal,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}
