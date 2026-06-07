import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../services/supabase_service.dart';

class KlaimHadiahScreen extends StatefulWidget {
  const KlaimHadiahScreen({super.key});
  @override
  State<KlaimHadiahScreen> createState() => _KlaimHadiahScreenState();
}

class _KlaimHadiahScreenState extends State<KlaimHadiahScreen> {
  List<Map<String, dynamic>> _rawClaims = [];
  bool _loading = true;
  final _bankCtrl = TextEditingController();
  String _method = 'Bank – BCA';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bankCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final data = await ClaimService.getMyClaims();
      if (mounted) {
        setState(() => _rawClaims = data);
      }
    } catch (e) {
      debugPrint('Error claims: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Konversi Map → KlaimModel (simplified for display)
  Map<String, dynamic> get _stats {
    int totalAvailable = 0;
    int totalProcessing = 0;
    int totalVerified = 0;
    
    for (final c in _rawClaims) {
      final status = c['status'] as String? ?? 'available';
      final amount = c['amount'] as int? ?? 0;
      if (status == 'available') {
        totalAvailable += amount;
      } else if (status == 'processing') {
        totalProcessing += amount;
      } else if (status == 'verified') {
        totalVerified += amount;
      }
    }
    
    return {
      'available': totalAvailable,
      'processing': totalProcessing,
      'verified': totalVerified,
    };
  }

  void _ajukan() async {
    if (_bankCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('⚠️ Nomor rekening tidak boleh kosong!'),
        backgroundColor: Color(0xFFFF1744)));
      return;
    }
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      // Find first available claim
      final available = _rawClaims.where((c) => c['status'] == 'available').firstOrNull;
      if (available == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('❌ Tidak ada hadiah yang tersedia untuk diklaim!'),
          backgroundColor: Color(0xFFFF1744)));
        return;
      }

      await ClaimService.requestClaim(
        claimId:       available['id'] as int,
        bankType:      _method.contains('Bank') ? 'bank' : 'ewallet',
        bankName:      _method.split('–').last.trim(),
        accountNumber: _bankCtrl.text.trim(),
        accountName:   Supabase.instance.client.auth.currentUser?.userMetadata?['name'] ?? '',
      );
      await _load(); // refresh data
      _bankCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Klaim diajukan!'),
          backgroundColor: Color(0xFF00C853)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ $e'), backgroundColor: const Color(0xFFFF1744)));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('KLAIM HADIAH')),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFB22222)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Summary cards
              Row(children: [
                Expanded(child: _statCard(Icons.account_balance_wallet_outlined, 'TERSEDIA', _fmtRupiah(_stats['available']), BooyahTheme.gold)),
                const SizedBox(width: 8),
                Expanded(child: _statCard(Icons.hourglass_empty_rounded, 'PROSES', _fmtRupiah(_stats['processing']), BooyahTheme.yellow)),
                const SizedBox(width: 8),
                Expanded(child: _statCard(Icons.check_circle_outline_rounded, 'TERKIRIM', _fmtRupiah(_stats['verified']), BooyahTheme.green)),
              ]),
              const SizedBox(height: 20),

              // Submit claim section
              if (_rawClaims.any((c) => c['status'] == 'available'))
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('AJUKAN KLAIM', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  
                  // Claim amount display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: BooyahTheme.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BooyahTheme.gold.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.monetization_on_outlined, color: BooyahTheme.gold, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Nominal Hadiah', style: TextStyle(fontSize: 10, color: BooyahTheme.textMuted)),
                        Text(_fmtRupiah((_rawClaims.firstWhere((c) => c['status'] == 'available')['amount'] as int?) ?? 0),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: BooyahTheme.gold)),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Bank selection dropdown
                  DropdownButton<String>(
                    value: _method,
                    isExpanded: true,
                    items: ['Bank – BCA', 'Bank – BRI', 'Bank – Mandiri', 'E-Wallet – OVO', 'E-Wallet – Dana']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => _method = v ?? _method),
                  ),
                  const SizedBox(height: 12),

                  // Account number input
                  TextField(
                    controller: _bankCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nomor rekening / e-wallet',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _ajukan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BooyahTheme.maroon,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('AJUKAN KLAIM', style: TextStyle(
                        fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),

              // Claim history
              if (_rawClaims.isNotEmpty)
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('RIWAYAT KLAIM', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  ..._rawClaims.map((c) {
                    final status = c['status'] as String? ?? 'available';
                    final statusColor = status == 'available' ? BooyahTheme.gold
                        : status == 'processing' ? BooyahTheme.yellow
                        : status == 'verified' ? BooyahTheme.green
                        : BooyahTheme.red;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: BooyahTheme.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(_statusLabel(status),
                            style: TextStyle(fontSize: 9, color: statusColor, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c['scrims']?['title'] ?? 'Scrim', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          Text('${c['match_results']?['rank'] ?? ''} · ${c['created_at'] ?? ''}',
                            style: const TextStyle(fontSize: 9, color: BooyahTheme.textMuted)),
                        ])),
                        Text(_fmtRupiah(c['amount'] as int? ?? 0),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor)),
                      ]),
                    );
                  }),
                ]),

              if (_rawClaims.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Belum ada riwayat klaim hadiah.',
                      style: TextStyle(color: BooyahTheme.textMuted)),
                  ),
                ),
            ]),
          ),
  );

  Widget _statCard(IconData icon, String label, String val, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: BooyahTheme.card,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(children: [
      Icon(icon, size: 24, color: color),
      const SizedBox(height: 4),
      Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 8, color: BooyahTheme.textMuted)),
    ]),
  );

  String _statusLabel(String s) {
    switch (s) {
      case 'available':   return 'TERSEDIA';
      case 'processing':  return 'PROSES';
      case 'verified':    return 'TERKIRIM';
      case 'rejected':    return 'DITOLAK';
      default:            return s.toUpperCase();
    }
  }
}
