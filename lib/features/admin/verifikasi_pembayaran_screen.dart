import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/supabase_service.dart';

class VerifikasiPembayaranScreen extends StatefulWidget {
  const VerifikasiPembayaranScreen({super.key});

  @override
  State<VerifikasiPembayaranScreen> createState() =>
      _VerifikasiPembayaranScreenState();
}

class _VerifikasiPembayaranScreenState
    extends State<VerifikasiPembayaranScreen> {
  bool _loading = true;
  late int scrimId;
  List<Map<String, dynamic>> _data = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrimId = ModalRoute.of(context)!.settings.arguments as int? ?? 1;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final regs = await RegistrationService.getByScrim(scrimId);
      setState(() {
        _data = regs.map((r) {
          final user = r['users'] as Map<String, dynamic>? ?? {};
          return {
            'id': r['id'],
            'team': r['team_name'] ?? '',
            'captain': user['name'] ?? r['captain_ff_id'] ?? '',
            'method': r['payment_method'] ?? r['payment_type'] ?? 'TRANSFER',
            'amount': _fmtRupiah(r['payment_amount'] as int? ?? 0),
            'status': r['status'] == 'verified'
                ? 'verified'
                : (r['status'] == 'rejected' || r['status'] == 'failed' || r['status'] == 'expired'
                    ? 'rejected'
                    : 'pending'),
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading payments: $e');
    } finally {
      setState(() => _loading = false);
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

  void _approve(int index) async {
    setState(() => _loading = true);
    try {
      final regId = _data[index]['id'] as int;
      await RegistrationService.updatePaymentStatus(
        registrationId: regId,
        newStatus: 'verified',
      );
      setState(() {
        _data[index]['status'] = 'verified';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran berhasil diverifikasi'),
            backgroundColor: BooyahTheme.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error approving payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal verifikasi pembayaran: $e'),
            backgroundColor: BooyahTheme.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _reject(int index) async {
    setState(() => _loading = true);
    try {
      final regId = _data[index]['id'] as int;
      await RegistrationService.updatePaymentStatus(
        registrationId: regId,
        newStatus: 'rejected',
      );
      setState(() {
        _data[index]['status'] = 'rejected';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran ditolak'),
            backgroundColor: BooyahTheme.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error rejecting payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menolak pembayaran: $e'),
            backgroundColor: BooyahTheme.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'verified':
        return BooyahTheme.green;
      case 'rejected':
        return BooyahTheme.red;
      default:
        return BooyahTheme.yellow;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'verified':
        return 'TERVERIFIKASI';
      case 'rejected':
        return 'DITOLAK';
      default:
        return 'PENDING';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('VERIFIKASI PEMBAYARAN'),
          actions: [
            Chip(
              label: const Text(
                'ADMIN',
                style: TextStyle(fontSize: 9),
              ),
              backgroundColor: BooyahTheme.yellow.withValues(alpha: 0.15),
              labelStyle: const TextStyle(
                color: BooyahTheme.yellow,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),

        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: BooyahTheme.maroon,
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _data.length,
                itemBuilder: (_, i) {
                  final d = _data[i];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: BooyahTheme.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: BooyahTheme.maroon.withValues(alpha: 0.2),
                      ),
                    ),

                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: BooyahTheme.maroon.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.groups_rounded,
                                color: BooyahTheme.yellow,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d['team'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),

                                  const SizedBox(height: 2),

                                  Text(
                                    'Captain: ${d['captain']}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: BooyahTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  d['status'],
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusLabel(d['status']),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: _statusColor(d['status']),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: BooyahTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              _infoRow(
                                'Metode Pembayaran',
                                d['method'],
                              ),
                              const SizedBox(height: 8),
                              _infoRow(
                                'Nominal',
                                d['amount'],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white10,
                            ),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  color: Colors.white38,
                                  size: 34,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Preview Bukti Transfer',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (d['status'] == 'pending') ...[
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _reject(i),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: BooyahTheme.red,
                                    ),
                                    foregroundColor: BooyahTheme.red,
                                  ),
                                  icon: const Icon(Icons.close_rounded),
                                  label: const Text('TOLAK'),
                                ),
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _approve(i),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: BooyahTheme.green,
                                  ),
                                  icon: const Icon(Icons.check),
                                  label: const Text('VERIFIKASI'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      );

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: BooyahTheme.textMuted,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}