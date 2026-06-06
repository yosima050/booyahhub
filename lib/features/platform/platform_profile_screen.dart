import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../core/auth_service.dart';

class PlatformProfileScreen extends StatefulWidget {
  const PlatformProfileScreen({super.key});

  @override
  State<PlatformProfileScreen> createState() => _PlatformProfileScreenState();
}

class _PlatformProfileScreenState extends State<PlatformProfileScreen> {
  final List<IconData> _avatarCollection = [
    Icons.apartment_rounded, // Indeks 0 (Gedung bawaan)
    Icons.admin_panel_settings, // Indeks 1
    Icons.gavel_rounded, // Indeks 2
    Icons.insights_rounded, // Indeks 3
    Icons.hub_rounded, // Indeks 4
    Icons.terminal_rounded, // Indeks 5
  ];

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // Fungsi untuk menarik data profil terupdate langsung dari Supabase
  Future<void> _fetchProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('users')
            .select()
            .eq('uuid', user.id)
            .single();

        if (mounted) {
          setState(() {
            _userData = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetch profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout(BuildContext ctx) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: BooyahTheme.card,
      title: const Text(
        'LOGOUT',
        style: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: const Text('Yakin ingin keluar dari dashboard platform?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'BATAL',
            style: TextStyle(color: BooyahTheme.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            AuthService().logout();
            await Supabase.instance.client.auth.signOut();
            if (ctx.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                ctx,
                AppRoutes.welcome,
                (r) => false,
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: BooyahTheme.red),
          child: const Text('KELUAR'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    final String displayName = _userData?['name'] ?? auth.name;
    final String? avatarUrl = _userData?['avatar_url'];
    final int avatarIndex = _userData?['avatar_index'] as int? ?? 0;

    return Scaffold(
      backgroundColor: BooyahTheme.bg,
      appBar: AppBar(title: const Text('PROFILE PLATFORM')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: BooyahTheme.maroonGlow),
            )
          : RefreshIndicator(
              color: BooyahTheme.maroonGlow,
              onRefresh: _fetchProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.editProfilPlat,
                        ).then((_) {
                          _fetchProfileData();
                        });
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF3A0000).withAlpha(204),
                              BooyahTheme.bg,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Lingkaran Foto Profil / Avatar System Hybrid
                            Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: BooyahTheme.maroonGlow,
                                    border: Border.all(
                                      color: BooyahTheme.maroonGlow.withAlpha(
                                        153,
                                      ),
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: BooyahTheme.maroonGlow.withAlpha(
                                          51,
                                        ),
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: avatarUrl != null
                                        ? Image.network(
                                            avatarUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Center(
                                                  child: Icon(
                                                    _avatarCollection[avatarIndex],
                                                    size: 36,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                          )
                                        : Center(
                                            child: Icon(
                                              _avatarCollection[avatarIndex],
                                              size: 36,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                                // Pemicu visual berupa penanda icon kamera kecil
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: BooyahTheme.card,
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 11,
                                      color: BooyahTheme.maroonGlow,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              displayName.isEmpty
                                  ? 'Super Owner Platform'
                                  : displayName,
                              style: const TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              auth.email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: BooyahTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: BooyahTheme.maroonGlow.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: BooyahTheme.maroonGlow.withAlpha(102),
                                ),
                              ),
                              child: const Text(
                                'SUPER ADMIN · PENGELOLA APLIKASI',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: BooyahTheme.maroonGlow,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _menuGroup('MANAJEMEN', [
                            (
                              Icons.people,
                              'Manajemen Akun',
                              AppRoutes.manajemenAkun,
                            ),
                            (
                              Icons.star,
                              'Kelola Premium',
                              AppRoutes.kelolaPremium,
                            ),
                            (
                              Icons.verified,
                              'Verifikasi Klaim',
                              AppRoutes.verifKlaim,
                            ),
                          ]),
                          const SizedBox(height: 10),
                          _menuGroup('LAPORAN & KEUANGAN', [
                            (
                              Icons.account_balance_wallet,
                              'Dashboard Keuangan',
                              AppRoutes.dashKeuangan,
                            ),
                            (
                              Icons.analytics,
                              'Laporan Keseluruhan',
                              AppRoutes.laporanPlat,
                            ),
                          ]),
                          const SizedBox(height: 10),

                          _menuGroup('SISTEM', [
                            (
                              Icons.person_outline,
                              'Edit Profil Platform',
                              AppRoutes.editProfilPlat,
                            ),
                            (Icons.security, 'Audit Log', AppRoutes.auditLog),
                          ]),
                          const SizedBox(height: 8),

                          GestureDetector(
                            onTap: () => _logout(context),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: BooyahTheme.red.withAlpha(20),
                                border: Border.all(
                                  color: BooyahTheme.red.withAlpha(76),
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: BooyahTheme.red,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'KELUAR',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: BooyahTheme.red,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _menuGroup(String title, List<(IconData, String, String?)> items) =>
      Container(
        decoration: BoxDecoration(
          color: BooyahTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BooyahTheme.maroon.withAlpha(51)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: BooyahTheme.textMuted,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...items.map(
              (m) => InkWell(
                onTap: m.$3 != null
                    ? () {
                        Navigator.pushNamed(context, m.$3!).then((_) {
                          if (m.$3 == AppRoutes.editProfilPlat) {
                            _fetchProfileData();
                          }
                        });
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(m.$1, color: BooyahTheme.maroonGlow, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        m.$2,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: BooyahTheme.textSec,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        color: BooyahTheme.textMuted,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
