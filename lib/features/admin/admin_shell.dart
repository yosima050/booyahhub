import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'admin_home_screen.dart';
import '../profile/admin_profile_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _idx = 0;

  final List<Widget> _screens = const [
    AdminHomeScreen(),
    AdminProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'DASHBOARD'),
    _NavItem(icon: Icons.manage_accounts_rounded, label: 'PROFIL'),
  ];

  @override
  Widget build(BuildContext ctx) => Scaffold(
    body: IndexedStack(index: _idx, children: _screens),
    bottomNavigationBar: Container(
      decoration: BoxDecoration(
        color: BooyahTheme.surface,
        border: const Border(top: BorderSide(color: BooyahTheme.yellow, width: 0.5)),
        boxShadow: [BoxShadow(color: BooyahTheme.yellow.withOpacity(0.05), blurRadius: 12)],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: _navItems.asMap().entries.map((e) {
              final active = _idx == e.key;
              final item   = e.value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _idx = e.key),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(item.icon, size: 22, color: active ? BooyahTheme.yellow : BooyahTheme.textMuted),
                    const SizedBox(height: 2),
                    Text(item.label, style: TextStyle(fontFamily:'Rajdhani', fontSize: 7,
                      fontWeight: FontWeight.w700, letterSpacing: 0.4,
                      color: active ? BooyahTheme.yellow : BooyahTheme.textMuted)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ),
  );
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
