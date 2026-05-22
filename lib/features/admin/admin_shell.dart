import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'admin_home_screen.dart';
import '../profile/admin_profile_screen.dart';
import 'buat_scrim_screen.dart';

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
    floatingActionButton: FloatingActionButton(
      onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const BuatScrimScreen())),
      backgroundColor: BooyahTheme.maroon,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.add, color: Colors.white, size: 24),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    bottomNavigationBar: Container(
      decoration: BoxDecoration(
        color: BooyahTheme.surface,
        border: const Border(top: BorderSide(color: BooyahTheme.yellow, width: 0.5)),
        boxShadow: [BoxShadow(color: BooyahTheme.yellow.withValues(alpha: 0.05), blurRadius: 12)],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              // DASHBOARD (Kiri)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _idx = 0),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_navItems[0].icon, size: 22, color: _idx == 0 ? BooyahTheme.yellow : BooyahTheme.textMuted),
                    const SizedBox(height: 2),
                    Text(_navItems[0].label, style: TextStyle(fontFamily:'Rajdhani', fontSize: 7,
                      fontWeight: FontWeight.w700, letterSpacing: 0.4,
                      color: _idx == 0 ? BooyahTheme.yellow : BooyahTheme.textMuted)),
                  ]),
                ),
              ),
              // Spacer untuk FAB (Tengah)
              const SizedBox(width: 56),
              // PROFIL (Kanan)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _idx = 1),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_navItems[1].icon, size: 22, color: _idx == 1 ? BooyahTheme.yellow : BooyahTheme.textMuted),
                    const SizedBox(height: 2),
                    Text(_navItems[1].label, style: TextStyle(fontFamily:'Rajdhani', fontSize: 7,
                      fontWeight: FontWeight.w700, letterSpacing: 0.4,
                      color: _idx == 1 ? BooyahTheme.yellow : BooyahTheme.textMuted)),
                  ]),
                ),
              ),
            ],
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
