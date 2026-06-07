import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../services/supabase_service.dart' show UserService;
import '../../services/user_service.dart' as user_svc;
import '../../shared/models/user_models.dart';
import '../../shared/models/enums/db_enums.dart';

class RekeningEwalletScreen extends StatefulWidget {
  const RekeningEwalletScreen({super.key});

  @override
  State<RekeningEwalletScreen> createState() => _RekeningEwalletScreenState();
}

class _RekeningEwalletScreenState extends State<RekeningEwalletScreen> {
  List<BankAccountModel> _accounts = [];
  bool _loading = true;
  int _userBigId = 0;

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
        _userBigId = profile['id'] as int;
        final list = await user_svc.UserService.getUserBankAccounts(_userBigId.toString());
        setState(() {
          _accounts = list;
        });
      }
    } catch (e) {
      debugPrint('Error loading accounts: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(BankAccountModel account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BooyahTheme.card,
        title: const Text(
          'HAPUS AKUN',
          style: TextStyle(fontFamily: 'Orbitron', fontSize: 14, fontWeight: FontWeight.w700),
        ),
        content: Text('Yakin ingin menghapus ${account.bankName} (${account.accountNumber})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('BATAL', style: TextStyle(color: BooyahTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: BooyahTheme.red),
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      final success = await user_svc.UserService.deleteBankAccount(account.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Akun berhasil dihapus'),
            backgroundColor: Color(0xFF00C853),
          ));
        }
        _loadData();
      } else {
        throw Exception('Gagal menghapus dari database');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menghapus: $e'),
          backgroundColor: const Color(0xFFFF1744),
        ));
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _setPrimary(BankAccountModel account) async {
    setState(() => _loading = true);
    try {
      final success = await user_svc.UserService.setPrimaryBankAccount(
        userId: _userBigId.toString(),
        bankAccountId: account.id,
      );
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Akun utama berhasil diperbarui'),
            backgroundColor: Color(0xFF00C853),
          ));
        }
        _loadData();
      } else {
        throw Exception('Gagal memperbarui akun utama');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mengubah akun utama: $e'),
          backgroundColor: const Color(0xFFFF1744),
        ));
      }
      setState(() => _loading = false);
    }
  }

  void _showAddDialog() {
    String bankTypeStr = 'Bank';
    String bankName = 'BCA';
    final accountNumCtrl = TextEditingController();
    final accountNameCtrl = TextEditingController();
    bool isPrimary = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BooyahTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isEWallet = bankTypeStr == 'E-Wallet';
          final methodList = isEWallet
              ? ['OVO', 'GOPAY', 'DANA', 'LinkAja']
              : ['BCA', 'BRI', 'Mandiri', 'BNI'];

          if (!methodList.contains(bankName)) {
            bankName = methodList.first;
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(modalCtx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TAMBAH REKENING / E-WALLET',
                  style: TextStyle(fontFamily: 'Orbitron', fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                const SizedBox(height: 16),

                // Bank Type Dropdown
                const Text('Tipe Akun', style: TextStyle(fontSize: 10, color: BooyahTheme.textMuted)),
                DropdownButton<String>(
                  value: bankTypeStr,
                  isExpanded: true,
                  dropdownColor: BooyahTheme.card,
                  items: ['Bank', 'E-Wallet']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        bankTypeStr = val;
                        bankName = val == 'E-Wallet' ? 'OVO' : 'BCA';
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Bank Name Dropdown
                const Text('Nama Penyedia', style: TextStyle(fontSize: 10, color: BooyahTheme.textMuted)),
                DropdownButton<String>(
                  value: bankName,
                  isExpanded: true,
                  dropdownColor: BooyahTheme.card,
                  items: methodList
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        bankName = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Account Number Input
                TextField(
                  controller: accountNumCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Rekening / E-Wallet',
                    labelStyle: TextStyle(fontSize: 12, color: BooyahTheme.textMuted),
                    hintText: 'Contoh: 1234567890',
                  ),
                ),
                const SizedBox(height: 12),

                // Account Name Input
                TextField(
                  controller: accountNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Pemilik Akun',
                    labelStyle: TextStyle(fontSize: 12, color: BooyahTheme.textMuted),
                    hintText: 'Nama lengkap sesuai rekening',
                  ),
                ),
                const SizedBox(height: 16),

                // Primary Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Jadikan Akun Utama', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Switch(
                      value: isPrimary,
                      activeThumbColor: BooyahTheme.yellow,
                      onChanged: (val) => setModalState(() => isPrimary = val),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (accountNumCtrl.text.trim().isEmpty || accountNameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('⚠️ Semua kolom harus diisi!'),
                          backgroundColor: Color(0xFFFF1744),
                        ));
                        return;
                      }

                      Navigator.pop(ctx);
                      setState(() => _loading = true);

                      try {
                        final type = bankTypeStr == 'Bank' ? BankType.bank : BankType.ewallet;
                        final res = await user_svc.UserService.addBankAccount(
                          userId: _userBigId.toString(),
                          bankType: type,
                          bankName: bankName,
                          accountNumber: accountNumCtrl.text.trim(),
                          accountName: accountNameCtrl.text.trim(),
                          isPrimary: isPrimary,
                        );

                        if (res != null) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Akun berhasil ditambahkan'),
                              backgroundColor: Color(0xFF00C853),
                            ));
                          }
                          _loadData();
                        } else {
                          throw Exception('Gagal menyimpan ke database');
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Gagal menyimpan: $e'),
                            backgroundColor: const Color(0xFFFF1744),
                          ));
                        }
                        setState(() => _loading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BooyahTheme.maroon,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'SIMPAN AKUN',
                      style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REKENING & E-WALLET'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: BooyahTheme.maroon),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: BooyahTheme.maroon,
              backgroundColor: BooyahTheme.card,
              child: _accounts.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada rekening/e-wallet tersimpan.',
                        style: TextStyle(color: BooyahTheme.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: _accounts.length,
                      itemBuilder: (context, index) {
                        final account = _accounts[index];
                        final isBank = account.bankType == BankType.bank;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: BooyahTheme.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: account.isPrimary
                                  ? BooyahTheme.gold
                                  : BooyahTheme.maroon.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isBank ? Icons.account_balance_rounded : Icons.phone_android_rounded,
                                    color: account.isPrimary ? BooyahTheme.gold : BooyahTheme.textSec,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    account.bankName,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  const Spacer(),
                                  if (account.isPrimary)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: BooyahTheme.gold.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: BooyahTheme.gold.withValues(alpha: 0.5)),
                                      ),
                                      child: const Text(
                                        'UTAMA',
                                        style: TextStyle(fontSize: 8, color: BooyahTheme.gold, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                account.accountNumber,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'a.n. ${account.accountName}',
                                style: const TextStyle(fontSize: 11, color: BooyahTheme.textMuted),
                              ),
                              const SizedBox(height: 14),
                              const Divider(height: 1, color: Colors.white10),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!account.isPrimary)
                                    TextButton.icon(
                                      onPressed: () => _setPrimary(account),
                                      icon: const Icon(Icons.star_outline_rounded, size: 16, color: BooyahTheme.gold),
                                      label: const Text('Jadikan Utama', style: TextStyle(fontSize: 11, color: BooyahTheme.gold)),
                                    ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _delete(account),
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: BooyahTheme.red),
                                    label: const Text('Hapus', style: TextStyle(fontSize: 11, color: BooyahTheme.red)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
      bottomNavigationBar: _loading
          ? null
          : Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text(
                    'TAMBAH AKUN',
                    style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BooyahTheme.yellow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
    );
  }
}
