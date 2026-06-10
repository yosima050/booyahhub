import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/auth_service.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../services/supabase_service.dart' as supabase_svc;
import 'kelola_scrim_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => AdminHomeScreenState();
}

class AdminHomeScreenState extends State<AdminHomeScreen> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _myScrim = [];
  bool _loading = true;
  String _activeFilter = 'SEMUA';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      // Sinkronisasi data profile admin jika belum terisi di AuthService
      final currentAuthUser = supabase_svc.AuthService.currentUser;
      if (currentAuthUser != null && AuthService().userId == 0) {
        final profile = await supabase_svc.UserService.getUserProfile(
          currentAuthUser.id,
        );
        final roleStr = profile['role'] as String? ?? 'admin';
        UserRole finalRole = UserRole.admin;
        if (roleStr == 'peserta') finalRole = UserRole.peserta;
        if (roleStr == 'platform') finalRole = UserRole.platform;

        AuthService().login(
          role: finalRole,
          name:
              profile['name'] as String? ??
              profile['email'] as String? ??
              'Admin',
          email: profile['email'] as String? ?? currentAuthUser.email ?? '',
          userId: profile['id'] as int? ?? 0,
        );
      }

      final dash = await supabase_svc.AdminService.getDashboard();
      if (mounted) {
        setState(() {
          _stats = dash['stats'] as Map<String, dynamic>? ?? {};
          _myScrim = List<Map<String, dynamic>>.from(
            dash['recent_scrims'] ?? [],
          );
        });
      }
    } catch (e) {
      debugPrint('Error admin dashboard: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'draft':
        return BooyahTheme.textMuted;
      case 'open':
        return BooyahTheme.yellow;
      case 'closed':
        return BooyahTheme.red;
      case 'ongoing':
        return BooyahTheme.maroonGlow;
      case 'finished':
        return BooyahTheme.green;
      default:
        return BooyahTheme.textMuted;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'draft':
        return 'DRAFT';
      case 'open':
        return 'BUKA';
      case 'closed':
        return 'PENUH';
      case 'ongoing':
        return 'LIVE';
      case 'finished':
        return 'SELESAI';
      default:
        return s.toUpperCase();
    }
  }

  String _fmtRupiah(int amount) {
    if (amount == 0) return 'Rp0';
    final formatter = amount.toString().split('').reversed.toList();
    String result = '';
    for (int i = 0; i < formatter.length; i++) {
      if (i > 0 && i % 3 == 0) result += '.';
      result += formatter[i];
    }
    return 'Rp${result.split('').reversed.join('')}';
  }

  @override
  Widget build(BuildContext ctx) {
    final adminName = AuthService().name;

    return Scaffold(
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB22222)),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 52, 16, 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF5C0000),
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
                            const Spacer(),
                            Stack(
                              children: [
                                Icon(
                                  Icons.notifications_outlined,
                                  color: BooyahTheme.textMuted,
                                  size: 20,
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: BooyahTheme.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Selamat datang,',
                          style: TextStyle(fontSize: 13, color: Colors.white54),
                        ),
                        Text(
                          adminName,
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
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
                        Expanded(
                          child: _kpiCard(
                            Icons.people,
                            'TIM TERDAFTAR',
                            '${_stats['total_teams'] ?? 0}',
                            'TOTAL',
                            BooyahTheme.maroonB,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _kpiCard(
                            Icons.attach_money,
                            'PEMASUKAN',
                            _fmtRupiah(_stats['gross_income'] as int? ?? 0),
                            'GROSS',
                            BooyahTheme.gold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _kpiCard(
                            Icons.emoji_events,
                            'SCRIM AKTIF',
                            '${_stats['active_scrims'] ?? 0}',
                            'LIVE',
                            BooyahTheme.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'SCRIM SAYA'),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children:
                                [
                                  'SEMUA',
                                  'DRAFT',
                                  'BUKA',
                                  'LIVE',
                                  'SELESAI',
                                ].map((filter) {
                                  final bool isSelected =
                                      _activeFilter == filter;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _activeFilter = filter,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? BooyahTheme.gold.withValues(
                                                  alpha: 0.2,
                                                )
                                              : BooyahTheme.card,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? BooyahTheme.gold
                                                : BooyahTheme.maroon.withValues(
                                                    alpha: 0.3,
                                                  ),
                                            width: 1.5,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: BooyahTheme.gold
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Text(
                                          filter,
                                          style: TextStyle(
                                            fontFamily: 'Orbitron',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1,
                                            color: isSelected
                                                ? BooyahTheme.gold
                                                : BooyahTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            final filteredScrims = _myScrim.where((s) {
                              final status = s['status'] as String? ?? 'open';
                              if (_activeFilter == 'SEMUA')
                                return status != 'finished';
                              if (_activeFilter == 'DRAFT') {
                                return status == 'draft';
                              }
                              if (_activeFilter == 'BUKA') {
                                return status == 'open' || status == 'closed';
                              }
                              if (_activeFilter == 'LIVE') {
                                return status == 'ongoing';
                              }
                              if (_activeFilter == 'SELESAI') {
                                return status == 'finished';
                              }
                              return true;
                            }).toList();

                            if (filteredScrims.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    'Belum ada scrim di kategori ini.',
                                    style: TextStyle(
                                      color: BooyahTheme.textMuted,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: filteredScrims
                                  .map(
                                    (s) => GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                KelolaScrimScreen(scrim: s),
                                          ),
                                        ).then(
                                          (_) => load(),
                                        ); // Refresh dashboard data when coming back
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: BooyahTheme.card,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: BooyahTheme.maroon
                                                .withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: _statusColor(
                                                  s['status'] as String? ??
                                                      'open',
                                                ).withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.sports_esports,
                                                  size: 18,
                                                  color: BooyahTheme.textMuted,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    s['title'] as String? ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${s['scheduled_at'] ?? ''}',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          BooyahTheme.textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _statusColor(
                                                      s['status'] as String? ??
                                                          'open',
                                                    ).withValues(alpha: 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    border: Border.all(
                                                      color: _statusColor(
                                                        s['status']
                                                                as String? ??
                                                            'open',
                                                      ).withValues(alpha: 0.4),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    _statusLabel(
                                                      s['status'] as String? ??
                                                          'open',
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: _statusColor(
                                                        s['status']
                                                                as String? ??
                                                            'open',
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${s['slot_filled'] ?? 0}/${s['slot_total'] ?? 0}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        BooyahTheme.textMuted,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _kpiCard(
    IconData icon,
    String label,
    String val,
    String trend,
    Color color,
  ) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: BooyahTheme.card,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 18, color: color),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                trend,
                style: TextStyle(
                  fontSize: 8,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            val,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 8, color: BooyahTheme.textMuted),
        ),
      ],
    ),
  );
}
