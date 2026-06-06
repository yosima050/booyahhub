import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../services/supabase_service.dart';

class VerifikasiKlaimScreen extends StatefulWidget {
  const VerifikasiKlaimScreen({super.key});

  @override
  State<VerifikasiKlaimScreen> createState() => _VerifikasiKlaimScreenState();
}

class _VerifikasiKlaimScreenState extends State<VerifikasiKlaimScreen> {
  List<Map<String, dynamic>> _claims = [];
  int _successCount = 0;
  int _totalClaims = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    try {
      if (mounted) {
        setState(() => _loading = true);
      }
      final data = await ClaimService.getPendingClaims();
      if (mounted) {
        setState(() {
          _claims = data;
          _totalClaims = data.length;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading claims: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _markDone(int i) async {
    try {
      final claim = _claims[i];
      await ClaimService.verifyClaim(
        claimId: claim['id'] as int,
        approve: true,
      );
      if (mounted) {
        setState(() {
          _claims.removeAt(i);
          _successCount++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transfer ke ${claim['user_name']} dikonfirmasi! Notifikasi terkirim.',
            ),
            backgroundColor: BooyahTheme.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking claim done: $e');
    }
  }

  void _reject(int i) async {
    final claim = _claims[i];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BooyahTheme.card,
        title: const Text(
          'Tolak Klaim?',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Saldo Rp${_fmt(claim['amount'] as int? ?? 0)} akan dikembalikan ke akun ${claim['user_name']}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'BATAL',
              style: TextStyle(color: BooyahTheme.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ClaimService.verifyClaim(
                  claimId: claim['id'] as int,
                  approve: false,
                  reason: 'Platform rejected',
                );
                if (mounted) {
                  setState(() {
                    _claims.removeAt(i);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Klaim ditolak. Saldo dikembalikan.'),
                      backgroundColor: BooyahTheme.yellow,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error rejecting claim: $e');
              }
            },
            child: const Text(
              'TOLAK',
              style: TextStyle(color: BooyahTheme.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(title: const Text('VERIFIKASI KLAIM')),
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFB22222)),
          )
        : Column(
            children: [
              // Summary bar: Menunggu, Selesai, dan Total
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                color: BooyahTheme.surface,
                child: Row(
                  children: [
                    _summaryChip(
                      Icons.hourglass_empty_rounded,
                      'Menunggu',
                      '${_claims.length}',
                      BooyahTheme.yellow,
                    ),
                    const SizedBox(width: 14),
                    _summaryChip(
                      Icons.check_circle_outline_rounded,
                      'Selesai',
                      '$_successCount',
                      BooyahTheme.green,
                    ),
                    const SizedBox(width: 14),
                    _summaryChip(
                      Icons.assignment_outlined,
                      'Total',
                      '$_totalClaims',
                      BooyahTheme.maroonB,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _claims.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada klaim menunggu verifikasi',
                          style: TextStyle(color: BooyahTheme.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _claims.length,
                        itemBuilder: (_, i) {
                          final c = _claims[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: BooyahTheme.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: i == 0
                                    ? BooyahTheme.gold.withValues(alpha: 0.35)
                                    : BooyahTheme.maroon.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.sports_esports_rounded,
                                      size: 26,
                                      color: BooyahTheme.maroonGlow,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c['team_name'] as String? ?? 'Team',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            '${c['user_name']} · ${c['scrim_title']}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: BooyahTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'Rp${_fmt(c['amount'] as int? ?? 0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: BooyahTheme.gold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BooyahTheme.surface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.account_balance,
                                        color: BooyahTheme.maroonB,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${c['bank_name']} ${c['account_number']}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      const StatusBadge(
                                        label: 'BELUM TRANSFER',
                                        color: BooyahTheme.yellow,
                                        showDot: false,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _markDone(i),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: BooyahTheme.green.withValues(
                                              alpha: 0.15,
                                            ),
                                            border: Border.all(
                                              color: BooyahTheme.green
                                                  .withValues(alpha: 0.4),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.check_rounded,
                                                size: 14,
                                                color: BooyahTheme.green,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'TRANSFER SELESAI',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: BooyahTheme.green,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => _reject(i),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: BooyahTheme.red.withValues(
                                            alpha: 0.1,
                                          ),
                                          border: Border.all(
                                            color: BooyahTheme.red.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.close_rounded,
                                              size: 14,
                                              color: BooyahTheme.red,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'TOLAK',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: BooyahTheme.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
  );

  Widget _summaryChip(IconData icon, String label, String val, Color color) =>
      Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(width: 4),
          Text(
            val,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      );

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(0)}k' : '$n';
}
