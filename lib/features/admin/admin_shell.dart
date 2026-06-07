import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import 'admin_home_screen.dart';
import '../profile/admin_profile_screen.dart';
import 'buat_scrim_screen.dart';
import 'admin_subscription_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _idx = 0;
  final GlobalKey<AdminHomeScreenState> _adminHomeKey =
      GlobalKey<AdminHomeScreenState>();

  late final List<Widget> _screens;
  bool _checkingSub = true;
  bool _isPremiumActive = false;
  DateTime? _premiumExpiredAt;

  @override
  void initState() {
    super.initState();
    _screens = [
      AdminHomeScreen(key: _adminHomeKey),
      const AdminProfileScreen(),
    ];
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final profile = await Supabase.instance.client
          .from('users')
          .select('id, admin_profiles(*)')
          .eq('uuid', user.id)
          .single();

      final adminProf = profile['admin_profiles'] as Map<String, dynamic>?;
      if (adminProf != null) {
        final bool isPremium = adminProf['is_premium'] as bool? ?? false;
        final String? expiredAtStr = adminProf['premium_expired_at'] as String?;
        final DateTime? expiredAt = expiredAtStr != null ? DateTime.parse(expiredAtStr) : null;

        bool isActive = false;
        if (isPremium) {
          if (expiredAt == null || expiredAt.isAfter(DateTime.now())) {
            isActive = true;
          }
        }

        if (mounted) {
          setState(() {
            _isPremiumActive = isActive;
            _premiumExpiredAt = expiredAt;
            _checkingSub = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isPremiumActive = false;
            _premiumExpiredAt = null;
            _checkingSub = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      if (mounted) {
        setState(() {
          _isPremiumActive = false;
          _premiumExpiredAt = null;
          _checkingSub = false;
        });
      }
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'DASHBOARD'),
    _NavItem(icon: Icons.manage_accounts_rounded, label: 'PROFIL'),
  ];

  @override
  Widget build(BuildContext ctx) {
    if (_checkingSub) {
      return const Scaffold(
        backgroundColor: BooyahTheme.bg,
        body: Center(
          child: CircularProgressIndicator(color: BooyahTheme.yellow),
        ),
      );
    }

    if (!_isPremiumActive) {
      return Scaffold(
        backgroundColor: BooyahTheme.bg,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF300000),
                Color(0xFF150000),
                BooyahTheme.bg,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.gpp_maybe_rounded,
                    color: BooyahTheme.yellow,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'AKSES ADMIN DIBATASI',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _premiumExpiredAt != null
                        ? 'Subscription Premium Anda telah berakhir pada ${_formatDate(_premiumExpiredAt!)}.'
                        : 'Anda belum memiliki subscription premium admin yang aktif.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: BooyahTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Aktifkan premium untuk mulai membuat scrim turnamen, mengelola peserta, dan mengakses dashboard admin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => const AdminSubscriptionScreen(),
                          ),
                        ).then((_) => _checkSubscription());
                      },
                      icon: const Icon(Icons.workspace_premium_rounded, color: Colors.black),
                      label: const Text(
                        'PILIH PAKET PREMIUM',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BooyahTheme.yellow,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (ctx.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          ctx,
                          AppRoutes.welcome,
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout, color: BooyahTheme.textMuted, size: 18),
                    label: const Text(
                      'KELUAR AKUN',
                      style: TextStyle(color: BooyahTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => const BuatScrimScreen()),
          );
          if (result == true) {
            _adminHomeKey.currentState?.load();
          }
        },
        backgroundColor: BooyahTheme.maroon,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: BooyahTheme.surface,
          border: const Border(
            top: BorderSide(color: BooyahTheme.yellow, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: BooyahTheme.yellow.withValues(alpha: 0.05),
              blurRadius: 12,
            ),
          ],
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _navItems[0].icon,
                          size: 22,
                          color: _idx == 0
                              ? BooyahTheme.yellow
                              : BooyahTheme.textMuted,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _navItems[0].label,
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: _idx == 0
                                ? BooyahTheme.yellow
                                : BooyahTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Spacer untuk FAB (Tengah)
                const SizedBox(width: 56),
                // PROFIL (Kanan)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _idx = 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _navItems[1].icon,
                          size: 22,
                          color: _idx == 1
                              ? BooyahTheme.yellow
                              : BooyahTheme.textMuted,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _navItems[1].label,
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: _idx == 1
                                ? BooyahTheme.yellow
                                : BooyahTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
