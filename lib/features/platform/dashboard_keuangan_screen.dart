// ──────────────────────────────────────────────────────────
// FILE: lib/features/platform/dashboard_keuangan_screen.dart
// UC-20: Dashboard Keuangan & Transaksi
// ──────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../services/supabase_service.dart';

class DashboardKeuanganScreen extends StatefulWidget {
  const DashboardKeuanganScreen({super.key});
  @override
  State<DashboardKeuanganScreen> createState() => _DashKeuanganState();
}

class _DashKeuanganState extends State<DashboardKeuanganScreen> {
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _transaksi = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final data = await PlatformService.getFinance();
      if (mounted) {
        setState(() {
          _summary = data['summary'] as Map<String, dynamic>? ?? {};
          _transaksi = List<Map<String, dynamic>>.from(
            data['transactions'] ?? [],
          );
        });
      }
    } catch (e) {
      debugPrint('Error finance: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Kelompokkan transaksi per bulan (12 bulan terakhir) → list 0.0–1.0
  List<double> _buildChartValues() {
    final now = DateTime.now();
    final monthly = List<int>.filled(12, 0);

    for (final t in _transaksi) {
      final raw = t['created_at'] as String?;
      if (raw == null) continue;
      final dt = DateTime.tryParse(raw)?.toLocal();
      if (dt == null) continue;
      final diff = (now.year - dt.year) * 12 + (now.month - dt.month);
      if (diff < 0 || diff >= 12) continue;
      final idx = 11 - diff; // bulan terlama = index 0, bulan ini = index 11
      monthly[idx] += (t['amount'] as num? ?? 0).toInt();
    }

    final maxVal = monthly.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return List.filled(12, 0.05); // bar minimal supaya tidak kosong
    return monthly.map((v) => v / maxVal).toList();
  }

  String _fmtRupiah(int amount) {
    final absAmount = amount.abs();
    if (absAmount == 0) return 'Rp0';
    final formatter = absAmount.toString().split('').reversed.toList();
    String result = '';
    for (int i = 0; i < formatter.length; i++) {
      if (i > 0 && i % 3 == 0) result += '.';
      result += formatter[i];
    }
    return 'Rp${result.split('').reversed.join('')}';
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
      title: const Text('KEUANGAN PLATFORM'),
      automaticallyImplyLeading: false,
      actions: [
        const SizedBox(width: 8),
      ],
    ),
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFB22222)),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main revenue card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [BooyahTheme.maroonD, Color(0xFF1A1000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: BooyahTheme.gold.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL PENDAPATAN PLATFORM',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white38,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fmtRupiah((_summary['gross_income'] as int?) ?? 0),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: BooyahTheme.gold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dari ${_summary['total_scrims'] ?? 0} scrim · ${_summary['total_teams'] ?? 0} tim · ${_summary['fee_percentage'] ?? 5}% fee',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Builder(builder: (ctx) {
                        final chartVals = _buildChartValues();
                        // Temukan index bulan ini (selalu index terakhir = 11)
                        return MiniBarChart(
                          values: chartVals,
                          highlightIndex: chartVals.length - 1,
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Summary strip
                Row(
                  children: [
                    _sumBox(
                      'GROSS',
                      _fmtRupiah((_summary['gross_income'] as int?) ?? 0),
                      BooyahTheme.gold,
                    ),
                    const SizedBox(width: 6),
                    _sumBox(
                      'FEE PLAT',
                      _fmtRupiah((_summary['platform_fee'] as int?) ?? 0),
                      BooyahTheme.red,
                    ),
                    const SizedBox(width: 6),
                    _sumBox(
                      'HADIAH',
                      _fmtRupiah((_summary['total_prizes'] as int?) ?? 0),
                      BooyahTheme.yellow,
                    ),
                    const SizedBox(width: 6),
                    _sumBox(
                      'FEE ADM',
                      _fmtRupiah((_summary['admin_fee'] as int?) ?? 0),
                      BooyahTheme.green,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Dana mengendap
                const SectionHeader(title: 'DANA MENGENDAP'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BooyahTheme.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: BooyahTheme.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MENUNGGU KLAIM HADIAH',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: BooyahTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _fmtRupiah(
                                  (_summary['pending_claims_amount'] as int?) ??
                                      0,
                                ),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: BooyahTheme.gold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: BooyahTheme.yellow.withValues(alpha: 0.1),
                              border: Border.all(
                                color: BooyahTheme.yellow.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_summary['pending_claims_count'] ?? 0} ANTRIAN',
                              style: const TextStyle(
                                fontSize: 9,
                                color: BooyahTheme.yellow,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      BooyahProgress(
                        label: 'Progress Payout',
                        valueLabel:
                            '${((_summary['payout_progress'] as int?) ?? 0)}%',
                        percent:
                            ((_summary['payout_progress'] as int?) ?? 0) /
                            100.0,
                        color: BooyahTheme.yellow,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Transaksi terbaru
                const SectionHeader(title: 'TRANSAKSI TERBARU'),
                if (_transaksi.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Belum ada transaksi.',
                        style: TextStyle(color: BooyahTheme.textMuted),
                      ),
                    ),
                  )
                else
                  ..._transaksi.map(
                    (t) => Container(
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BooyahTheme.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: BooyahTheme.maroon.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: BooyahTheme.maroon.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.monetization_on,
                                size: 18,
                                color: BooyahTheme.gold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['description'] as String? ?? '',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${t['scrim_title'] ?? ''} · ${t['created_at'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: BooyahTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(t['amount'] as int? ?? 0) >= 0 ? '+' : '-'}${_fmtRupiah((t['amount'] as int?) ?? 0)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: (t['amount'] as int? ?? 0) >= 0
                                  ? BooyahTheme.green
                                  : BooyahTheme.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
  );

  Widget _sumBox(String label, String val, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: BooyahTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 8, color: BooyahTheme.textMuted),
          ),
        ],
      ),
    ),
  );
}
