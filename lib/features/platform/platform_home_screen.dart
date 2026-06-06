import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../core/auth_service.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../services/supabase_service.dart' hide AuthService;

class PlatformHomeScreen extends StatefulWidget {
  const PlatformHomeScreen({super.key});
  @override
  State<PlatformHomeScreen> createState() => _PlatformHomeScreenState();
}

class _PlatformHomeScreenState extends State<PlatformHomeScreen> {
  int _userCount = 0, _scrimCount = 0, _claimPending = 0, _adminPending = 0;
  String _transactionTotal = 'Rp0';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() => _loading = true);
      }

      final currentAuthUser = Supabase.instance.client.auth.currentUser;
      if (currentAuthUser != null && AuthService().userId == 0) {
        final profile = await UserService.getUserProfile(currentAuthUser.id);
        final roleStr = profile['role'] as String? ?? 'platform';
        UserRole finalRole = UserRole.platform;
        if (roleStr == 'peserta') finalRole = UserRole.peserta;
        if (roleStr == 'admin') finalRole = UserRole.admin;

        AuthService().login(
          role: finalRole,
          name:
              profile['name'] as String? ??
              profile['email'] as String? ??
              'Platform Admin',
          email: profile['email'] as String? ?? currentAuthUser.email ?? '',
          userId: profile['id'] as int? ?? 0,
        );
      }

      final users = await PlatformService.getUsers(limit: 100);
      final scrims = await ScrimService.getAll(limit: 100);
      final claims = await ClaimService.getPendingClaims();
      final premium = await PlatformService.getPremiumRequests();

      final txData = await PlatformService.getFinance();
      final summary = txData['summary'] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _userCount = (users as List).length;
          _scrimCount = (scrims as List).length;
          _claimPending = (claims as List).length;
          _adminPending = (premium as List).length;
          _transactionTotal = _fmtRupiah(summary['total_revenue'] as int? ?? 0);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading platform data: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _fmtRupiah(int val) {
    if (val >= 1000000) return 'Rp${(val / 1000000).toStringAsFixed(0)}jt';
    if (val >= 1000) return 'Rp${(val / 1000).toStringAsFixed(0)}k';
    return 'Rp$val';
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFB22222)),
          )
        : SafeArea(
            top: true,
            bottom: true,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF3A0000),
                          Color(0xFF1A0000),
                          BooyahTheme.bg,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(child: const Row(children: [])),
                            const Spacer(),
                            Container(
                              child: const Row(
                                children: [const SizedBox(height: 10)],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Halo, ${Supabase.instance.client.auth.currentUser?.userMetadata?['name'] ?? 'Admin'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white54,
                          ),
                        ),
                        const Text(
                          'BOOYAHHUB PLATFORM',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Apr 2026 · Sistem berjalan normal',
                          style: TextStyle(fontSize: 11, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                    child: Row(
                      children: [
                        _bigStat(
                          _userCount.toString(),
                          'PENGGUNA',
                          BooyahTheme.maroonB,
                        ),
                        _divider(),
                        _bigStat(
                          _scrimCount.toString(),
                          'SCRIM',
                          BooyahTheme.green,
                        ),
                        _divider(),
                        _bigStat(
                          _transactionTotal,
                          'TRANSAKSI',
                          BooyahTheme.gold,
                        ),
                      ],
                    ),
                  ),
                ),

                // Dua alert card notifikasi:
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    child: Column(
                      children: [
                        _alertCard(
                          Icons.hourglass_empty_rounded,
                          'Klaim Hadiah Menunggu',
                          '$_claimPending permintaan klaim belum diproses',
                          BooyahTheme.yellow,
                          () => Navigator.pushNamed(ctx, AppRoutes.verifKlaim),
                          ctaLabel: 'PROSES',
                        ),
                        const SizedBox(height: 8),
                        _alertCard(
                          Icons.gavel_rounded,
                          'Admin Pending Approval',
                          '$_adminPending admin baru mengajukan upgrade',
                          BooyahTheme.maroonGlow,
                          () =>
                              Navigator.pushNamed(ctx, AppRoutes.kelolaPremium),
                          ctaLabel: 'REVIEW',
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'LAYANAN MANAJEMEN'),
                        Row(
                          children: [
                            _serviceCard(
                              'MANAJEMEN\nAKUN',
                              Icons.people_rounded,
                              BooyahTheme.yellow,
                              () => Navigator.pushNamed(
                                ctx,
                                AppRoutes.manajemenAkun,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _serviceCard(
                              'LAYANAN\nPREMIUM',
                              Icons.card_membership_rounded,
                              BooyahTheme.gold,
                              () => Navigator.pushNamed(
                                ctx,
                                AppRoutes.kelolaPremium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _serviceCard(
                              'VERIFIKASI\nKLAIM',
                              Icons.verified_rounded,
                              BooyahTheme.maroonGlow,
                              () => Navigator.pushNamed(
                                ctx,
                                AppRoutes.verifKlaim,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _serviceCard(
                              'KEUANGAN\nPLATFORM',
                              Icons.bar_chart_rounded,
                              BooyahTheme.green,
                              () => Navigator.pushNamed(
                                ctx,
                                AppRoutes.dashKeuangan,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
  );

  Widget _serviceCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _bigStat(String value, String label, Color color) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white38,
          ),
        ),
      ],
    ),
  );

  Widget _divider() => Container(width: 1, height: 30, color: Colors.white12);

  // Fungsi _alertCard:
  Widget _alertCard(
    IconData icon,
    String title,
    String description,
    Color color,
    VoidCallback onTap, {
    required String ctaLabel,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Menggunakan Widget Icon bawaan Flutter dengan warna yang dinamis
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 9, color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              border: Border.all(color: color.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ctaLabel,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
