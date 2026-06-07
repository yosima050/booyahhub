import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'platform_home_screen.dart';
import 'manajemen_akun_screen.dart';
import 'verifikasi_klaim_screen.dart';
import 'dashboard_keuangan_screen.dart';
import 'platform_profile_screen.dart';

class PlatformShell extends StatefulWidget {
  const PlatformShell({super.key});
  @override
  State<PlatformShell> createState() => _PlatformShellState();
}

class _PlatformShellState extends State<PlatformShell> {
  int _idx = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      PlatformHomeScreen(
        onTabChanged: (index) {
          setState(() => _idx = index);
        },
      ),
      const ManajemenAkunScreen(),   // index 1
      const VerifikasiKlaimScreen(), // index 2
      const DashboardKeuanganScreen(), // index 3
      PlatformProfileScreen(
        onTabChanged: (index) {
          setState(() => _idx = index);
        },
      ), // index 4
    ];
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    body: IndexedStack(index: _idx, children: _screens),
    bottomNavigationBar: Container(
      decoration: BoxDecoration(
        color: BooyahTheme.surface,
        border: const Border(top: BorderSide(color: BooyahTheme.maroonGlow, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              _navItem(0, Icons.space_dashboard_rounded, 'LAYANAN'),
              _navItem(1, Icons.people_rounded, 'AKUN'),
              _navItem(2, Icons.verified_rounded, 'KLAIM'),
              _navItem(3, Icons.bar_chart_rounded, 'KEUANGAN'),
              _navItem(4, Icons.admin_panel_settings_rounded, 'PROFIL'),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _navItem(int idx, IconData icon, String label) {
    final active = _idx == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _idx = idx),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 22, color: active ? BooyahTheme.maroonGlow : BooyahTheme.textMuted),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontFamily:'Rajdhani', fontSize:7,
            fontWeight:FontWeight.w700, letterSpacing:0.4,
            color: active ? BooyahTheme.maroonGlow : BooyahTheme.textMuted)),
        ]),
      ),
    );
  }
}
