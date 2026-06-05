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
  int _periodIdx = 1;
  final _periods = ['7H','30H','3B','6B','1T','SEMUA'];
  
  Map<String, dynamic> _report = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      setState(() => _loading = true);
      final data = await PlatformService.getReport();
      setState(() {
        _report = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading report: $e');
      setState(() => _loading = false);
    }
  }



  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
      title: const Text('LAPORAN PLATFORM'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFB22222)))
        : _report.isEmpty
        ? const Center(child: Text('Data tidak cukup untuk dianalisis.',
            style: TextStyle(color: BooyahTheme.textMuted)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Period filter
              Row(children: _periods.asMap().entries.map((e) => Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _periodIdx = e.key);
                    _loadReport();
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: e.key < 5 ? 4 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: _periodIdx == e.key ? BooyahTheme.maroon : BooyahTheme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: BooyahTheme.maroon.withValues(alpha: _periodIdx == e.key ? 0.8 : 0.2)),
                    ),
                    child: Text(e.value, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                        color: _periodIdx == e.key ? Colors.white : BooyahTheme.textMuted)),
                  ),
                ),
              )).toList()),
              const SizedBox(height: 12),

              // Big KPI numbers
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
                    _report['total_users']?.toString() ?? '0', 
                    '+${_report['new_users']?.toString() ?? '0'} baru', 
                    BooyahTheme.maroonB,
                  ),
                  _bigKpi(
                    Icons.emoji_events_rounded, 
                    'Total Scrim', 
                    _report['total_scrims']?.toString() ?? '0', 
                    '+${_report['new_scrims_this_month']?.toString() ?? '0'} bulan ini', 
                    BooyahTheme.green,
                  ),
                  _bigKpi(
                    Icons.account_balance_wallet_rounded, 
                    'Total Transaksi', 
                    _fmtRupiah(_report['total_revenue'] as int? ?? 0), 
                    '${_report['revenue_growth_percentage']?.toString() ?? '0'}% vs bulan lalu', 
                    BooyahTheme.gold,
                  ),
                  _bigKpi(
                    Icons.stars_rounded, 
                    'Admin Premium', 
                    _report['premium_admins']?.toString() ?? '0', 
                    '${_report['new_premium_admins']?.toString() ?? '0'} baru bergabung',
                    BooyahTheme.yellow,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Growth chart
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
                  const Text('PERTUMBUHAN PENGGUNA', style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1.5)),
                  RichText(text: TextSpan(
                    text: '${_report['total_users']?.toString() ?? '0'} ',
                    style: const TextStyle(fontFamily:'Orbitron', fontSize: 20, fontWeight: FontWeight.w900, color: BooyahTheme.textPri),
                    children: [TextSpan(text: '↑ ${_report['new_users']?.toString() ?? '0'}', style: const TextStyle(fontSize: 13, color: BooyahTheme.green))],
                  )),
                  const SizedBox(height: 12),
                  MiniBarChart(values: _report['chart_data'] as List<double>? ?? List.filled(12, 0.5)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Text(
                        _getStartPeriodLabel(_periodIdx), 
                        style: const TextStyle(fontSize: 9, color: Colors.white24),
                      ),
                      Text(
                        _getEndPeriodLabel(_periodIdx), 
                        style: const TextStyle(fontSize: 9, color: Colors.white24),
                      ),
                    ],
                  ),
                ]),
              ),
              const SizedBox(height: 14),

              // Role distribution (visual)
              const SectionHeader(title: 'DISTRIBUSI ROLE'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BooyahTheme.card, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
                ),
                child: Column(children: [
                  Builder(
                    builder: (context) {
                      final int jmlPeserta = _report['role_peserta_count'] as int? ?? 0;
                      final int jmlAdmin = _report['role_admin_count'] as int? ?? 0;
                      final int jmlPlatform = _report['role_platform_count'] as int? ?? 0;
                     
                      final int totalUser = jmlPeserta + jmlAdmin + jmlPlatform;
                      final int totalSistem = totalUser == 0 ? 1 : totalUser; 

                      return Column(
                        children: [
                          _distRow('Peserta', jmlPeserta, totalSistem, BooyahTheme.maroonB),
                          _distRow('Admin', jmlAdmin, totalSistem, BooyahTheme.yellow),
                          _distRow('Platform', jmlPlatform, totalSistem, BooyahTheme.maroonGlow),
                        ],
                      );
                    }
                  )
                ]),
              ),
              const SizedBox(height: 14),

              // Top admin
              const SectionHeader(title: 'TOP ADMIN SCRIM'),
              ...(_report['top_admins'] as List? ?? []).asMap().entries.map((e) {
                final a = e.value as Map<String, dynamic>;
                
                IconData rankIcon;
                Color iconColor;
                
                if (e.key == 0) {
                  rankIcon = Icons.emoji_events_rounded; 
                  iconColor = BooyahTheme.gold;
                } else if (e.key == 1) {
                  rankIcon = Icons.emoji_events_rounded; 
                  iconColor = const Color(0xFFC0C0C0); 
                } else if (e.key == 2) {
                  rankIcon = Icons.emoji_events_rounded; 
                  iconColor = const Color(0xFFCD7F32); 
                } else {
                  rankIcon = Icons.military_tech_rounded; 
                  iconColor = BooyahTheme.textMuted;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 7),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: BooyahTheme.card, 
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Icon(rankIcon, color: iconColor, size: 24),
                    const SizedBox(width: 10),
                    
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a['admin_name'] as String? ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      Text('${a['total_scrims_created']} scrim · ${_fmtRupiah(a['total_revenue'] as int? ?? 0)}', style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted)),
                    ])),
                    StatusBadge(
                      label: a['is_premium'] == true ? 'Premium' : 'Reguler', showDot: false,
                      color: a['is_premium'] == true ? BooyahTheme.gold : BooyahTheme.green,
                    ),
                  ]),
                );
              }),
              const SizedBox(height: 14),

              // System health
              const SectionHeader(title: 'KESEHATAN SISTEM'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BooyahTheme.card, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
                ),
                child: Column(children: [
                  Column(
                    children: [
                      BooyahProgress(
                        label: 'Uptime Server', 
                        valueLabel: '${_report['system_uptime']?.toString() ?? '100'}%', 
                        percent: (_report['system_uptime_pct'] as num? ?? 1.0).toDouble(),
                      ),
                      BooyahProgress(
                        label: 'Verifikasi Rata-rata', 
                        valueLabel: _report['avg_verification_time'] as String? ?? '-', 
                        percent: (_report['verification_speed_pct'] as num? ?? 1.0).toDouble(),
                      ),
                      BooyahProgress(
                        label: 'Kepuasan Pengguna', 
                        valueLabel: '${_report['user_satisfaction']?.toString() ?? '5.0'}/5.0', 
                        percent: (_report['satisfaction_pct'] as num? ?? 1.0).toDouble(),
                      ),
                      BooyahProgress(
                        label: 'Scrim Berhasil', 
                        valueLabel: '${_report['scrim_success_rate']?.toString() ?? '100'}%', 
                        percent: (_report['scrim_success_pct'] as num? ?? 1.0).toDouble(),
                      ),
                    ],
                  )
                ]),
              ),
              const SizedBox(height: 20),
            ]),
          ),
  );

  String _getStartPeriodLabel(int idx) {
    switch (idx) {
      case 0: return '7 Hari Lalu';
      case 1: return '30 Hari Lalu';
      case 2: return '3 Bulan Lalu';
      case 3: return '6 Bulan Lalu';
      case 4: return '1 Tahun Lalu';
      default: return 'Awal Platform';
    }
  }

  String _getEndPeriodLabel(int idx) {
    switch (idx) {
      case 0: 
      case 1: return 'Hari Ini';
      default: return 'Bulan Ini';
    }
  }

  String _fmtRupiah(int val) {
    if (val >= 1000000) return 'Rp${(val / 1000000).toStringAsFixed(0)}jt';
    if (val >= 1000) return 'Rp${(val / 1000).toStringAsFixed(0)}k';
    return 'Rp$val';
  }

 Widget _bigKpi(IconData icon, String label, String val, String sub, Color color) =>
    Container(
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
    final pct = val / total;
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
}
