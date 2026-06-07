import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../services/supabase_service.dart' show UserService;
import '../../services/user_service.dart' as user_svc;

class RiwayatPembayaranScreen extends StatefulWidget {
  const RiwayatPembayaranScreen({super.key});

  @override
  State<RiwayatPembayaranScreen> createState() => _RiwayatPembayaranScreenState();
}

class _RiwayatPembayaranScreenState extends State<RiwayatPembayaranScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loading = true);
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await UserService.getUserProfile(user.id);
        final int userBigId = profile['id'] as int;
        final txList = await user_svc.UserService.getUserTransactions(userBigId);
        setState(() {
          _transactions = txList;
        });
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      setState(() => _loading = false);
    }
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

  String _fmtDate(String isoStr) {
    try {
      final d = DateTime.parse(isoStr).toLocal();
      const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${d.day} ${m[d.month]} ${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoStr;
    }
  }

  bool _isExpense(String type, int amount) {
    if (amount < 0) return true;
    if (type == 'registration_fee' || type == 'premium_fee' || type == 'platform_fee') return true;
    return false;
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'registration_fee':
        return 'Biaya Registrasi';
      case 'premium_fee':
        return 'Pembelian Premium';
      case 'platform_fee':
        return 'Biaya Platform';
      case 'admin_fee':
        return 'Biaya Admin';
      case 'prize_payout':
        return 'Klaim Hadiah';
      case 'refund':
        return 'Refund Dana';
      default:
        return type.toUpperCase().replaceAll('_', ' ');
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'registration_fee':
        return Icons.sports_esports_outlined;
      case 'premium_fee':
        return Icons.workspace_premium_outlined;
      case 'prize_payout':
        return Icons.emoji_events_outlined;
      case 'refund':
        return Icons.replay_outlined;
      default:
        return Icons.payment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RIWAYAT PEMBAYARAN'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: BooyahTheme.maroon),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: BooyahTheme.maroon,
              backgroundColor: BooyahTheme.card,
              child: _transactions.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada riwayat transaksi.',
                        style: TextStyle(color: BooyahTheme.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final tx = _transactions[index];
                        final String type = tx['type'] as String? ?? 'registration_fee';
                        final int amount = (tx['amount'] as num? ?? 0).toInt();
                        final String desc = tx['description'] as String? ?? '';
                        final String dateStr = tx['created_at'] as String? ?? '';
                        final bool expense = _isExpense(type, amount);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: BooyahTheme.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: BooyahTheme.maroon.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: (expense ? BooyahTheme.red : BooyahTheme.green).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getTypeIcon(type),
                                  color: expense ? BooyahTheme.red : BooyahTheme.green,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getTypeLabel(type),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      desc,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _fmtDate(dateStr),
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color: BooyahTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${expense ? '-' : '+'}${_fmtRupiah(amount)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: expense ? BooyahTheme.red : BooyahTheme.green,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
