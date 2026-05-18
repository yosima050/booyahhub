// ──────────────────────────────────────────────────────────
// FILE: lib/features/platform/verifikasi_klaim_screen.dart
// UC-05: Verifikasi Klaim Hadiah
// ──────────────────────────────────────────────────────────
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
  List<int> _processed = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    try {
      setState(() => _loading = true);
      final data = await ClaimService.getPendingClaims();
      setState(() {
        _claims = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading claims: $e');
      setState(() => _loading = false);
    }
  }

  void _markDone(int i) async {
    try {
      final claim = _claims[i];
      await ClaimService.verifyClaim(
        claimId: claim['id'] as int,
        approve: true,
      );
      setState(() => _processed.add(i));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Transfer ke ${claim['user_name']} dikonfirmasi! Notifikasi terkirim.'),
          backgroundColor: BooyahTheme.green));
    } catch (e) {
      debugPrint('Error marking claim done: $e');
    }
  }

  void _reject(int i) async {
    final claim = _claims[i];
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: BooyahTheme.card,
      title: const Text('Tolak Klaim?', style: TextStyle(fontFamily:'Rajdhani',fontSize:14,fontWeight:FontWeight.w700)),
      content: Text('Saldo Rp${_fmt(claim['amount'] as int? ?? 0)} akan dikembalikan ke akun ${claim['user_name']}.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('BATAL', style: TextStyle(color: BooyahTheme.textMuted))),
        TextButton(onPressed: () async {
          Navigator.pop(context);
          try {
            await ClaimService.verifyClaim(
              claimId: claim['id'] as int,
              approve: false,
              reason: 'Platform rejected',
            );
            setState(() => _processed.add(i));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🔄 Klaim ditolak. Saldo dikembalikan.'),
                backgroundColor: BooyahTheme.yellow));
          } catch (e) {
            debugPrint('Error rejecting claim: $e');
          }
        }, child: const Text('TOLAK', style: TextStyle(color: BooyahTheme.red))),
      ],
    ));
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(title: const Text('VERIFIKASI KLAIM'),
      actions: [Chip(label: const Text('PLATFORM', style: TextStyle(fontSize: 9)),
        backgroundColor: BooyahTheme.maroonGlow.withOpacity(0.15),
        labelStyle: const TextStyle(color: BooyahTheme.maroonGlow, fontWeight: FontWeight.w700),
      ), const SizedBox(width: 8)]),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFB22222)))
        : Column(
      children: [
        // Summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: BooyahTheme.surface,
          child: Row(children: [
            _summaryChip('⏳ Menunggu', '${_claims.where((c) => !_processed.contains(_claims.indexOf(c))).length}', BooyahTheme.yellow),
            const SizedBox(width: 14),
            _summaryChip('✅ Selesai', '${_processed.length}', BooyahTheme.green),
            const SizedBox(width: 14),
            _summaryChip('📋 Total', '${_claims.length}', BooyahTheme.maroonB),
          ]),
        ),

        Expanded(
          child: _claims.isEmpty
              ? const Center(child: Text('Tidak ada klaim menunggu verifikasi', style: TextStyle(color: BooyahTheme.textMuted)))
              : ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: _claims.length,
            itemBuilder: (_, i) {
              final c = _claims[i];
              final done = _processed.contains(i);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: done ? BooyahTheme.green.withOpacity(0.05) : BooyahTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: i == 0 && !done
                      ? BooyahTheme.gold.withOpacity(0.35)
                      : done ? BooyahTheme.green.withOpacity(0.25)
                      : BooyahTheme.maroon.withOpacity(0.2)),
                ),
                child: Column(children: [
                  // Header
                  Row(children: [
                    const Text('🎮', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c['team_name'] as String? ?? 'Team', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      Text('${c['user_name']} · ${c['scrim_title']}',
                        style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted)),
                    ])),
                    Text('Rp${_fmt(c['amount'] as int? ?? 0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: BooyahTheme.gold)),
                  ]),
                  const SizedBox(height: 8),
                  // Bank info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: BooyahTheme.surface, borderRadius: BorderRadius.circular(6)),
                    child: Row(children: [
                      const Icon(Icons.account_balance, color: BooyahTheme.maroonB, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${c['bank_name']} ${c['account_number']}', style: const TextStyle(fontSize: 11))),
                      done
                          ? const StatusBadge(label: 'TERKIRIM', color: BooyahTheme.green, showDot: false)
                          : const StatusBadge(label: 'BELUM TRANSFER', color: BooyahTheme.yellow, showDot: false),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  // Actions
                  if (!done) Row(children: [
                    Expanded(child: GestureDetector(
                      onTap: () => _markDone(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: BooyahTheme.green.withOpacity(0.15),
                          border: Border.all(color: BooyahTheme.green.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text('✓ TRANSFER SELESAI', textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: BooyahTheme.green, letterSpacing: 0.5)),
                      ),
                    )),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _reject(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: BooyahTheme.red.withOpacity(0.1),
                          border: Border.all(color: BooyahTheme.red.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text('✕ TOLAK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: BooyahTheme.red)),
                      ),
                    ),
                  ]) else
                    const Center(child: Text('✅ Transfer telah dikonfirmasi',
                      style: TextStyle(fontSize: 11, color: BooyahTheme.green, fontWeight: FontWeight.w600))),
                ]),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _summaryChip(String label, String val, Color color) => Row(children: [
    Text(label, style: TextStyle(fontSize: 11, color: color)),
    const SizedBox(width: 4),
    Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
  ]);

  String _fmt(int n) => n >= 1000 ? '${(n/1000).toStringAsFixed(0)}k' : '$n';
}
