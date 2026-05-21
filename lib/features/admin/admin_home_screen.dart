import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/auth_service.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../services/supabase_service.dart' as supabase_svc;

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _myScrim = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dash = await supabase_svc.AdminService.getDashboard();
      setState(() {
        _stats   = dash['stats'] as Map<String,dynamic>? ?? {};
        _myScrim = List<Map<String,dynamic>>.from(dash['recent_scrims'] ?? []);
      });
    } catch (e) {
      debugPrint('Error admin dashboard: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'open':     return BooyahTheme.yellow;
      case 'closed':   return BooyahTheme.red;
      case 'ongoing':  return BooyahTheme.maroonGlow;
      case 'finished': return BooyahTheme.green;
      default:         return BooyahTheme.textMuted;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'open':     return 'BUKA';
      case 'closed':   return 'PENUH';
      case 'ongoing':  return 'LIVE';
      case 'finished': return 'SELESAI';
      default:         return s.toUpperCase();
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB22222)))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 52, 16, 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5C0000), Color(0xFF1A0000), BooyahTheme.bg],
                        begin: Alignment.topLeft, end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: BooyahTheme.yellow.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: BooyahTheme.yellow.withValues(alpha: 0.4)),
                          ),
                          child: const Row(children: [
                            Icon(Icons.star, size: 12, color: BooyahTheme.yellow),
                            SizedBox(width: 4),
                            Text('ADMIN', style: TextStyle(fontSize: 9, color: BooyahTheme.yellow, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                        const Spacer(),
                        Stack(children: [
                          Icon(Icons.notifications_outlined, color: BooyahTheme.textMuted, size: 20),
                          Positioned(right: 0, top: 0,
                            child: Container(width: 6, height: 6, decoration: const BoxDecoration(
                              color: BooyahTheme.red, shape: BoxShape.circle))),
                        ]),
                      ]),
                      const SizedBox(height: 14),
                      const Text('Selamat datang,', style: TextStyle(fontSize: 13, color: Colors.white54)),
                      Text(adminName, style: const TextStyle(fontFamily: 'Orbitron', fontSize: 20,
                        fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ]),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                    child: GridView.count(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8,
                      childAspectRatio: 1.9,
                      children: [
                        _kpiCard('👥', 'TIM TERDAFTAR', '${_stats['total_teams'] ?? 0}', '+${_stats['new_teams_today'] ?? 0}', BooyahTheme.maroonB),
                        _kpiCard('💰', 'PEMASUKAN', _fmtRupiah(_stats['total_income'] as int? ?? 0), '↑ ${_stats['income_growth'] ?? '0%'}', BooyahTheme.gold),
                        _kpiCard('⏳', 'PENDING VERIF', '${_stats['pending_verifications'] ?? 0}', 'SEGERA', BooyahTheme.yellow),
                        _kpiCard('🏆', 'SCRIM AKTIF', '${_stats['active_scrims'] ?? 0}', 'LIVE', BooyahTheme.green),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SectionHeader(title: 'SCRIM SAYA'),
                      if (_myScrim.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('Belum ada scrim.', style: TextStyle(color: BooyahTheme.textMuted))))
                      else
                        ..._myScrim.map((s) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: BooyahTheme.card,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
                              ),
                              child: Row(children: [
                                Container(width: 40, height: 40,
                                  decoration: BoxDecoration(color: _statusColor(s['status'] as String? ?? 'open').withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8)),
                                  child: const Center(child: Text('🎮', style: TextStyle(fontSize: 18)))),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(s['title'] as String? ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                  Text('${s['scheduled_at'] ?? ''}', style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted)),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _statusColor(s['status'] as String? ?? 'open').withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: _statusColor(s['status'] as String? ?? 'open').withValues(alpha: 0.4)),
                                    ),
                                    child: Text(_statusLabel(s['status'] as String? ?? 'open'), style: TextStyle(
                                      fontSize: 9, color: _statusColor(s['status'] as String? ?? 'open'), fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${s['slot_filled'] ?? 0}/${s['slot_total'] ?? 0}', style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted, fontWeight: FontWeight.w600)),
                                ]),
                              ]),
                            )),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _kpiCard(String ico, String label, String val, String trend, Color color) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: BooyahTheme.card, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(ico, style: const TextStyle(fontSize: 18)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(3)),
              child: Text(trend, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 8, color: BooyahTheme.textMuted)),
        ]),
      );
}
