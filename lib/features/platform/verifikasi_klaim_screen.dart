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
  int? _processingId;

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
    final claim = _claims[i];
    final claimId = claim['id'] as int;
    if (_processingId != null) return;

    setState(() => _processingId = claimId);
    try {
      await ClaimService.verifyClaim(
        claimId: claimId,
        approve: true,
      );
      if (mounted) {
        setState(() {
          _claims.removeAt(i);
          _successCount++;
          _processingId = null;
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
      if (mounted) {
        setState(() => _processingId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memverifikasi klaim: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: BooyahTheme.red,
          ),
        );
      }
    }
  }

  void _reject(int i) async {
    final claim = _claims[i];
    final claimId = claim['id'] as int;
    if (_processingId != null) return;

    final detailCtrl = TextEditingController();
    String selectedReason = 'Indikasi Cheat / Curang';
    final List<String> reasons = [
      'Indikasi Cheat / Curang',
      'Data Rekening Salah / Tidak Valid',
      'Melanggar Regulasi Scrim',
      'Lainnya',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final bool isLainnya = selectedReason == 'Lainnya';
            final bool isValid = !isLainnya || detailCtrl.text.trim().isNotEmpty;

            return AlertDialog(
              backgroundColor: BooyahTheme.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: BooyahTheme.red.withValues(alpha: 0.3),
                ),
              ),
              title: Row(
                children: const [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: BooyahTheme.red,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'TOLAK KLAIM HADIAH',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Rp${_fmt(claim['amount'] as int? ?? 0)} akan dikembalikan ke akun ${claim['user_name']}.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ALASAN UTAMA PENOLAKAN',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: BooyahTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedReason,
                      dropdownColor: BooyahTheme.card,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: BooyahTheme.red,
                          ),
                        ),
                      ),
                      items: reasons.map((r) {
                        return DropdownMenuItem<String>(
                          value: r,
                          child: Text(r),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedReason = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'ALASAN LANJUT / KETERANGAN',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: BooyahTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: detailCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: isLainnya
                            ? 'Wajib diisi...'
                            : 'Keterangan tambahan (opsional)...',
                        hintStyle: const TextStyle(
                          fontSize: 11,
                          color: Colors.white30,
                        ),
                        contentPadding: const EdgeInsets.all(10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: BooyahTheme.red,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    detailCtrl.dispose();
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'BATAL',
                    style: TextStyle(
                      color: BooyahTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BooyahTheme.red,
                    disabledBackgroundColor: BooyahTheme.red.withValues(
                      alpha: 0.3,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: !isValid
                      ? null
                      : () async {
                          final customReason = detailCtrl.text.trim();
                          final String finalReason = isLainnya
                              ? customReason
                              : (customReason.isNotEmpty
                                  ? '$selectedReason - $customReason'
                                  : selectedReason);
                          detailCtrl.dispose();
                          Navigator.pop(ctx);

                          setState(() => _processingId = claimId);
                          try {
                            await ClaimService.verifyClaim(
                              claimId: claimId,
                              approve: false,
                              reason: finalReason,
                            );
                            if (mounted) {
                              setState(() {
                                _claims.removeAt(i);
                                _processingId = null;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Klaim ditolak: $finalReason. Saldo dikembalikan.',
                                  ),
                                  backgroundColor: BooyahTheme.yellow,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('Error rejecting claim: $e');
                            if (mounted) {
                              setState(() => _processingId = null);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gagal menolak klaim: ${e.toString().replaceAll('Exception: ', '')}',
                                  ),
                                  backgroundColor: BooyahTheme.red,
                                ),
                              );
                            }
                          }
                        },
                  child: const Text(
                    'TOLAK KLAIM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
      title: const Text('VERIFIKASI KLAIM'),
      automaticallyImplyLeading: false,
    ),
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
                                            '${c['team_name'] as String? ?? 'Team'} (Juara ${c['rank'] ?? '-'})',
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
                                        onTap: _processingId != null ? null : () => _markDone(i),
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
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              _processingId == c['id']
                                                  ? const SizedBox(
                                                      width: 14,
                                                      height: 14,
                                                      child: CircularProgressIndicator(
                                                        color: BooyahTheme.green,
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.check_rounded,
                                                      size: 14,
                                                      color: BooyahTheme.green,
                                                    ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'SETUJUI & KIRIM HADIAH',
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
                                      onTap: _processingId != null ? null : () => _reject(i),
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
