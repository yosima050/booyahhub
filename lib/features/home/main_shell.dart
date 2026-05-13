import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'home_screen.dart';
import '../booking/booking_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../notification/notification_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const HomeScreen(),
    const BookingScreen(),
    const LeaderboardScreen(),
    const NotificationScreen(),
    const ProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_rounded,          label: 'HOME'),
    _NavItem(icon: Icons.calendar_month_rounded, label: 'BOOKING'),
    _NavItem(icon: Icons.emoji_events_rounded,   label: 'RANK'),
    _NavItem(icon: Icons.notifications_rounded,  label: 'NOTIF'),
    _NavItem(icon: Icons.person_rounded,         label: 'PROFIL'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: BooyahTheme.maroon, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: _navItems.map((n) => BottomNavigationBarItem(
            icon: Icon(n.icon),
            label: n.label,
          )).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}