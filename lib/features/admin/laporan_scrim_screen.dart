// ──────────────────────────────────────────────────────────
// FILE: lib/features/admin/laporan_scrim_screen.dart
// UC-18: Melihat Laporan Scrim
// ──────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../services/supabase_service.dart';

class LaporanScrimScreen extends StatefulWidget {
  const LaporanScrimScreen({super.key});

  @override
  State<LaporanScrimScreen> createState() => _LaporanScrimScreenState();
}

class _LaporanScrimScreenState extends State<LaporanScrimScreen> {
  int _periodIdx = 1;
  final _periods = ['7 HARI','30 HARI','3 BULAN','SEMUA'];
  List<Map<String, dynamic>> _scrimData = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loading = true);
      final days = [7, 30, 90, 0][_periodIdx]; // 0 = all time
      final report = await AdminService.getScrimReport(days: days);
      setState(() {
        _scrimData = List<Map<String, dynamic>>.from(report['scrims'] ?? []);
        _stats = report['stats'] as Map<String, dynamic>? ?? {};
      });
    } catch (e) {
      debugPrint('Error loading report: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  bool get _hasData => _scrimData.isNotEmpty;

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(title: const Text('LAPORAN SCRIM'),
      actions: [Chip(label: const Text('ADMIN', style: TextStyle(fontSize: 9)),
        backgroundColor: BooyahTheme.yellow.withValues(alpha: 0.15),
        labelStyle: const TextStyle(color: BooyahTheme.yellow, fontWeight: FontWeight.w700),
      ), const SizedBox(width: 8)]),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: BooyahTheme.maroon))
        : !_hasData
            ? const Center(child: Text('Belum ada data scrim untuk ditampilkan.',
                style: TextStyle(color: BooyahTheme.textMuted)))
            : SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Period filter
              Row(children: _periods.asMap().entries.map((e) => Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _periodIdx = e.key);
                    _loadData();
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: e.key < 3 ? 5 : 0),
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

              // KPI Grid
              GridView.count(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8,
                childAspectRatio: 2.0,
                children: [
                  _kpiCard('🏆', 'TOTAL SCRIM', '${_stats['total_scrims'] ?? 0}', '+${_stats['new_scrims'] ?? 0}', true),
                  _kpiCard('👥', 'TOTAL TIM', '${_stats['total_teams'] ?? 0}', '+${_stats['new_teams'] ?? 0}', true),
                  _kpiCard('💰', 'PENDAPATAN', _fmt(_stats['total_revenue'] ?? 0), '↑${_stats['revenue_change'] ?? 0}%', true),
                  _kpiCard('✅', 'VERIF RATE', '${_stats['verification_rate'] ?? 0}%', '${_stats['verification_rate'] ?? 0}%', true),
                ],
              ),
              const SizedBox(height: 12),

              // Revenue chart
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
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('PENDAPATAN BERSIH', style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1.5)),
                      Text(_fmt(_stats['net_revenue'] ?? 0), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: BooyahTheme.gold)),
                    ]),
                    Text('↑ ${_stats['revenue_change'] ?? 0}%', style: const TextStyle(fontSize: 11, color: BooyahTheme.green, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 10),
                  MiniBarChart(values: _stats['chart_data'] ?? List.filled(12, 0.5)),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(_getChartStartDate(), style: const TextStyle(fontSize: 9, color: Colors.white24)),
                    Text(_getChartEndDate(), style: const TextStyle(fontSize: 9, color: Colors.white24)),
                  ]),
                ]),
              ),
              const SizedBox(height: 14),

              // Per-scrim performance
              const SectionHeader(title: 'PERFORMA PER SCRIM'),
              ..._scrimData.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BooyahTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
                ),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['name'] as String,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      Text('${s['date']} · ${s['slot']} Tim',
                        style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted)),
                    ])),
                    Text(_fmt(s['rev'] as int? ?? 0),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: BooyahTheme.gold)),
                  ]),
                  const SizedBox(height: 8),
                  BooyahProgress(
                    label: 'Slot Terisi',
                    valueLabel: '${((s['pct'] as double? ?? 0) * 100).toInt()}%',
                    percent: s['pct'] as double? ?? 0,
                    color: (s['pct'] as double? ?? 0) == 1.0 ? BooyahTheme.green : BooyahTheme.maroonB,
                  ),
                ]),
              )),
            ]),
          ),
  );

  Widget _kpiCard(String ico, String label, String val, String trend, bool isUp) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: BooyahTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(ico, style: const TextStyle(fontSize: 18)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: (isUp ? BooyahTheme.green : BooyahTheme.yellow).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(trend, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                color: isUp ? BooyahTheme.green : BooyahTheme.yellow)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(fontSize: 9, color: BooyahTheme.textMuted)),
        ]),
      );

  String _fmt(int n) => n >= 1000000 ? '${(n/1000000).toStringAsFixed(1)}jt' : '${(n/1000).toStringAsFixed(0)}k';

  String _getChartStartDate() {
    final days = [7, 30, 90, 0][_periodIdx];
    if (days == 0) return '1 Jan';
    final d = DateTime.now().subtract(Duration(days: days));
    return '${d.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month - 1]}';
  }

  String _getChartEndDate() {
    final now = DateTime.now();
    return '${now.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][now.month - 1]} ${now.year}';
  }
}