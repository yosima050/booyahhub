import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../services/supabase_service.dart';

class LaporanPlatformScreen extends StatefulWidget {
  const LaporanPlatformScreen({super.key});

  @override
  State<LaporanPlatformScreen> createState() => _LaporanPlatformScreenState();
}

class _LaporanPlatformScreenState extends State<LaporanPlatformScreen> {
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _topAdmins = [];
  List<Map<String, dynamic>> _userRoles = [];
  List<Map<String, dynamic>> _scrims = [];
  List<Map<String, dynamic>> _recentUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await PlatformService.getReport();
      if (!mounted) return;
      setState(() {
        _summary = data['summary'] as Map<String, dynamic>? ?? {};
        _topAdmins = List<Map<String, dynamic>>.from(data['top_admins'] ?? []);
        _userRoles = List<Map<String, dynamic>>.from(data['user_roles'] ?? []);
        _scrims = List<Map<String, dynamic>>.from(data['scrims'] ?? []);
        _recentUsers = List<Map<String, dynamic>>.from(data['recent_users'] ?? []);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading report: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ── Hitungan dari data real ──────────────────────────────

  int get _totalUsers => _userRoles.length;
  int get _pesertaCount => _userRoles.where((u) => u['role'] == 'peserta').length;
  int get _adminCount => _userRoles.where((u) => u['role'] == 'admin').length;
  int get _platformCount => _userRoles.where((u) => u['role'] == 'platform').length;

  int get _totalScrims => _scrims.length;
  int get _activeScrims => _scrims.where((s) => s['status'] == 'open').length;
  int get _doneScrims => _scrims.where((s) => s['status'] == 'selesai').length;

  /// Pengguna baru dalam 30 hari terakhir
  int get _newUsersThisMonth {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _recentUsers.where((u) {
      final raw = u['created_at'] as String?;
      if (raw == null) return false;
      final dt = DateTime.tryParse(raw);
      return dt != null && dt.isAfter(cutoff);
    }).length;
  }

  /// Bar chart: jumlah user per bulan (12 bulan terakhir), normalized 0.0–1.0
  List<double> _buildUserGrowthChart() {
    final now = DateTime.now();
    final monthly = List<int>.filled(12, 0);
    for (final u in _recentUsers) {
      final raw = u['created_at'] as String?;
      if (raw == null) continue;
      final dt = DateTime.tryParse(raw)?.toLocal();
      if (dt == null) continue;
      final diff = (now.year - dt.year) * 12 + (now.month - dt.month);
      if (diff < 0 || diff >= 12) continue;
      monthly[11 - diff]++;
    }
    final maxVal = monthly.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return List.filled(12, 0.05);
    return monthly.map((v) => v / maxVal).toList();
  }

  String _fmtRupiah(int val) {
    if (val >= 1000000) return 'Rp${(val / 1000000).toStringAsFixed(1)}jt';
    if (val >= 1000) return 'Rp${(val / 1000).toStringAsFixed(0)}k';
    return 'Rp$val';
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
      title: const Text('LAPORAN PLATFORM'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: _loadReport,
          tooltip: 'Refresh',
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFB22222)))
        : RefreshIndicator(
            onRefresh: _loadReport,
            color: BooyahTheme.maroonB,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── KPI Grid ──────────────────────────────
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.8,
                  children: [
                    _bigKpi(
                      Icons.people_alt_rounded,
                      'Total Pengguna',
                      _totalUsers.toString(),
                      '+$_newUsersThisMonth baru 30 hari ini',
                      BooyahTheme.maroonB,
                    ),
                    _bigKpi(
                      Icons.emoji_events_rounded,
                      'Total Scrim',
                      _totalScrims.toString(),
                      '$_activeScrims aktif · $_doneScrims selesai',
                      BooyahTheme.green,
                    ),
                    _bigKpi(
                      Icons.account_balance_wallet_rounded,
                      'Total Pendapatan',
                      _fmtRupiah((_summary['gross_income'] as int?) ?? 0),
                      'Fee platform: ${_fmtRupiah((_summary['platform_fee'] as int?) ?? 0)}',
                      BooyahTheme.gold,
                    ),
                    _bigKpi(
                      Icons.admin_panel_settings_rounded,
                      'Jumlah Admin',
                      _adminCount.toString(),
                      '${_topAdmins.where((a) => a['is_premium'] == true).length} premium aktif',
                      BooyahTheme.yellow,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Pertumbuhan Pengguna (bar chart real) ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [BooyahTheme.maroonD, Color(0xFF1A1000)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('PERTUMBUHAN PENGGUNA (12 BLN TERAKHIR)',
                      style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    RichText(text: TextSpan(
                      text: '$_totalUsers ',
                      style: const TextStyle(fontFamily: 'Orbitron', fontSize: 20, fontWeight: FontWeight.w900, color: BooyahTheme.textPri),
                      children: [TextSpan(
                        text: '↑ $_newUsersThisMonth baru',
                        style: const TextStyle(fontSize: 12, color: BooyahTheme.green, fontFamily: 'Rajdhani'),
                      )],
                    )),
                    const SizedBox(height: 12),
                    MiniBarChart(
                      values: _buildUserGrowthChart(),
                      highlightIndex: 11,
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('11 Bulan Lalu', style: TextStyle(fontSize: 9, color: Colors.white24)),
                        Text('Bulan Ini', style: TextStyle(fontSize: 9, color: Colors.white24)),
                      ],
                    ),
                  ]),
                ),
                const SizedBox(height: 14),

                // ── Distribusi Role ───────────────────────
                const SectionHeader(title: 'DISTRIBUSI ROLE'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BooyahTheme.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
                  ),
                  child: Column(children: [
                    _distRow('Peserta', _pesertaCount, _totalUsers == 0 ? 1 : _totalUsers, BooyahTheme.maroonB),
                    _distRow('Admin', _adminCount, _totalUsers == 0 ? 1 : _totalUsers, BooyahTheme.yellow),
                    _distRow('Platform', _platformCount, _totalUsers == 0 ? 1 : _totalUsers, BooyahTheme.maroonGlow),
                  ]),
                ),
                const SizedBox(height: 14),

                // ── Status Scrim ──────────────────────────
                const SectionHeader(title: 'STATUS SCRIM'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BooyahTheme.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
                  ),
                  child: Column(children: [
                    _distRow('Open / Aktif', _activeScrims, _totalScrims == 0 ? 1 : _totalScrims, BooyahTheme.green),
                    _distRow('Selesai', _doneScrims, _totalScrims == 0 ? 1 : _totalScrims, BooyahTheme.gold),
                    _distRow('Dibatalkan / Lainnya',
                      _totalScrims - _activeScrims - _doneScrims,
                      _totalScrims == 0 ? 1 : _totalScrims,
                      BooyahTheme.textMuted),
                  ]),
                ),
                const SizedBox(height: 14),

                // ── Top Admin Scrim ───────────────────────
                const SectionHeader(title: 'TOP ADMIN SCRIM'),
                if (_topAdmins.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text('Belum ada data admin.', style: TextStyle(color: BooyahTheme.textMuted))),
                  )
                else
                  ..._topAdmins.asMap().entries.map((e) {
                    final a = e.value;
                    final Color rankColor = switch (e.key) {
                      0 => BooyahTheme.gold,
                      1 => const Color(0xFFC0C0C0),
                      2 => const Color(0xFFCD7F32),
                      _ => BooyahTheme.textMuted,
                    };

                    return Container(
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BooyahTheme.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: rankColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: rankColor.withValues(alpha: 0.4)),
                          ),
                          child: Center(
                            child: Text('${e.key + 1}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: rankColor)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            a['display_name'] as String? ?? 'Admin',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${a['total_scrims_created'] ?? 0} scrim · ${a['total_participants'] ?? 0} peserta',
                            style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted),
                          ),
                        ])),
                        StatusBadge(
                          label: a['is_premium'] == true ? 'Premium' : 'Reguler',
                          showDot: false,
                          color: a['is_premium'] == true ? BooyahTheme.gold : BooyahTheme.green,
                        ),
                      ]),
                    );
                  }),
                const SizedBox(height: 14),

                // ── Ringkasan Keuangan ────────────────────
                const SectionHeader(title: 'RINGKASAN KEUANGAN'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BooyahTheme.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: BooyahTheme.gold.withValues(alpha: 0.2)),
                  ),
                  child: Column(children: [
                    _finRow('Gross Income', _fmtRupiah((_summary['gross_income'] as int?) ?? 0), BooyahTheme.gold),
                    _finRow('Fee Platform', _fmtRupiah((_summary['platform_fee'] as int?) ?? 0), BooyahTheme.red),
                    _finRow('Total Hadiah Dibayar', _fmtRupiah((_summary['total_prizes'] as int?) ?? 0), BooyahTheme.yellow),
                    _finRow('Pending Klaim Hadiah', _fmtRupiah((_summary['pending_claims_amount'] as int?) ?? 0), BooyahTheme.textMuted),
                    const Divider(color: Colors.white12, height: 20),
                    _finRow('Total Tim Terdaftar', '${_summary['total_teams'] ?? 0} tim', BooyahTheme.maroonB),
                    _finRow('Total Scrim', '${_summary['total_scrims'] ?? 0} scrim', BooyahTheme.green),
                  ]),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
  );

  Widget _bigKpi(IconData icon, String label, String val, String sub, Color color) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: BooyahTheme.card,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.25)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(height: 6),
      Text(val, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 9, color: BooyahTheme.textMuted)),
      Text(sub, style: const TextStyle(fontSize: 9, color: BooyahTheme.green)),
    ]),
  );

  Widget _distRow(String label, int val, int total, Color color) {
    final pct = (val / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          Text('$val (${(pct * 100).toStringAsFixed(0)}%)',
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: pct, backgroundColor: BooyahTheme.surface,
            valueColor: AlwaysStoppedAnimation(color), minHeight: 6),
        ),
      ]),
    );
  }

  Widget _finRow(String label, String val, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: BooyahTheme.textMuted)),
      Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}
