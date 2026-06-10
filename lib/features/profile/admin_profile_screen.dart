import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../core/auth_service.dart';
import '../../shared/models/models.dart';
import '../../services/supabase_service.dart' show UserService, AdminService;
import '../../services/user_service.dart' as user_svc;
import '../../shared/models/user_models.dart';
import '../../shared/models/enums/db_enums.dart' hide UserRole;
import 'edit_profile_screen.dart';
import 'bantuan_faq_screen.dart';
import '../admin/admin_subscription_screen.dart';
import 'rekening_ewallet_screen.dart';
import 'riwayat_pembayaran_screen.dart';
import '../notification/notification_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _loading = true;
  bool _uploadingPhoto = false;
  RealtimeChannel? _profileChannel;

  int _adminBalance = 0;
  int _totalEarnings = 0;
  int _totalWithdrawn = 0;
  int _totalProcessing = 0;
  int? _adminBigId;


  @override
  void initState() {
    super.initState();
    _loadUserData();
    _subscribeToProfileChanges();
  }

  void _subscribeToProfileChanges() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _profileChannel = Supabase.instance.client
        .channel('profile_sync_admin_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'uuid',
            value: user.id,
          ),
          callback: (payload) {
            debugPrint('Realtime admin profile updated: ${payload.newRecord}');
            _loadUserData();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _profileChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userData = await UserService.getUserProfile(user.id);
        final int adminId = userData['id'];
        _adminBigId = adminId;

        // Load admin balance
        try {
          final balanceRes = await AdminService.getAdminBalance(adminId);
          if (mounted) {
            setState(() {
              _adminBalance = balanceRes['available_balance'] ?? 0;
              _totalEarnings = balanceRes['total_earnings'] ?? 0;
              _totalWithdrawn = balanceRes['total_withdrawn'] ?? 0;
              _totalProcessing = balanceRes['total_processing'] ?? 0;
            });
          }
        } catch (balError) {
          debugPrint('Error loading admin balance: $balError');
        }

        // Count all scrims created by this admin dynamically (fallback/immediate fix)
        int scrimsCount = 0;
        try {
          final scrimsRes = await Supabase.instance.client
              .from('scrims')
              .select('id')
              .eq('admin_id', adminId)
              .isFilter('deleted_at', null);
          scrimsCount = (scrimsRes as List).length;
        } catch (scrimError) {
          debugPrint('Error counting scrims dynamically: $scrimError');
        }

        // Inject total_scrims_created dynamically
        final dynamic adminProfData = userData['admin_profiles'];
        if (adminProfData != null) {
          if (adminProfData is List && adminProfData.isNotEmpty) {
            final profileMap = Map<String, dynamic>.from(adminProfData.first);
            profileMap['total_scrims_created'] = scrimsCount;
            userData['admin_profiles'] = [profileMap];
          } else if (adminProfData is Map) {
            final profileMap = Map<String, dynamic>.from(adminProfData);
            profileMap['total_scrims_created'] = scrimsCount;
            userData['admin_profiles'] = profileMap;
          }
        }

        if (mounted) {
          setState(() {
            _userData = userData;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading admin profile: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String? _getAvatarUrl() {
    final fromProfile = _userData?['avatar_url'] as String?;
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;

    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['avatar_url'] as String? ??
        user?.userMetadata?['picture'] as String?;
  }

  Future<void> _pickAndUploadPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final ext = (file.extension ?? 'jpg').toLowerCase();
      final filePath = 'avatars/${user.id}.$ext';

      // Upload ke Supabase Storage bucket "avatars"
      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            file.bytes!,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
          );

      // Ambil public URL
      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // Simpan ke tabel users berdasarkan uuid
      await Supabase.instance.client
          .from('users')
          .update({'avatar_url': publicUrl})
          .eq('uuid', user.id);

      setState(() {
        _userData = {...?_userData, 'avatar_url': publicUrl};
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil admin berhasil diperbarui!')),
        );
      }
    } catch (e) {
      debugPrint('Upload photo error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal upload foto: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  void _logout(BuildContext ctx) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: BooyahTheme.card,
      title: const Text('LOGOUT', style: TextStyle(fontFamily:'Orbitron', fontSize:14, fontWeight:FontWeight.w700)),
      content: const Text('Yakin ingin keluar dari akun admin?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('BATAL', style: TextStyle(color: BooyahTheme.textMuted))),
        ElevatedButton(
          onPressed: () async {
            AuthService().logout();
            await Supabase.instance.client.auth.signOut();
            if (ctx.mounted) {
              Navigator.pushNamedAndRemoveUntil(ctx, AppRoutes.welcome, (r) => false);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: BooyahTheme.red),
          child: const Text('KELUAR'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext ctx) {
    final auth = AuthService();

    dynamic adminProfData = _userData?['admin_profiles'];
    Map<String, dynamic>? adminProfile;
    if (adminProfData is List && adminProfData.isNotEmpty) {
      adminProfile = adminProfData.first as Map<String, dynamic>?;
    } else if (adminProfData is Map) {
      adminProfile = Map<String, dynamic>.from(adminProfData);
    }
    final bool isPremium = adminProfile?['is_premium'] as bool? ?? false;
    final String? expiredAtStr = adminProfile?['premium_expired_at'] as String?;

    bool isPremiumActive = false;
    int remainingDays = 0;
    if (isPremium && expiredAtStr != null) {
      final expiredAt = DateTime.parse(expiredAtStr);
      remainingDays = expiredAt.difference(DateTime.now()).inDays;
      if (remainingDays > 0) {
        isPremiumActive = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFIL ADMIN'),
        actions:  [const SizedBox(width: 8)],
      ),
      body: _loading 
          ? const Center(child: CircularProgressIndicator(color: BooyahTheme.yellow))
          : SingleChildScrollView(
              child: Column(children: [
                Container(
                  width: double.infinity, padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF5C0000).withValues(alpha: 0.8), BooyahTheme.bg],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  ),
                  child: Column(children: [
                    _buildAvatar(),
                    const SizedBox(height: 10),
                    Text(_userData?['name'] ?? auth.name, style: const TextStyle(
                      fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPremiumActive 
                            ? BooyahTheme.yellow.withValues(alpha: 0.15)
                            : BooyahTheme.textMuted.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPremiumActive ? BooyahTheme.yellow.withValues(alpha: 0.4) : BooyahTheme.textMuted.withValues(alpha: 0.4)
                        ),
                      ),
                      child: Text(
                        isPremiumActive ? '★ ADMIN PREMIUM' : '★ BASIC ADMIN', 
                        style: TextStyle(
                          fontSize: 10, 
                          color: isPremiumActive ? BooyahTheme.yellow : BooyahTheme.textMuted, 
                          fontWeight: FontWeight.w700, 
                          letterSpacing: 1
                        )
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _stat('${adminProfile?['total_scrims_created'] ?? 0}', 'SCRIM\nDIBUAT'),
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.white.withValues(alpha: 0.15),
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        _stat(_formatCurrency(_adminBalance), 'SALDO\nEARNINGS'),
                      ],
                    ),
                  ]),
                ),

                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isPremiumActive 
                            ? BooyahTheme.yellow.withValues(alpha: 0.06)
                            : BooyahTheme.textMuted.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPremiumActive ? BooyahTheme.yellow.withValues(alpha: 0.3) : BooyahTheme.textMuted.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            isPremiumActive ? '⭐' : '⚪',
                            style: const TextStyle(fontSize: 28),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPremiumActive ? 'Premium Aktif' : 'Premium Tidak Aktif',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  isPremiumActive ? '$remainingDays hari tersisa' : 'Silakan lakukan pembayaran',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isPremiumActive ? BooyahTheme.yellow : BooyahTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                  builder: (_) => const AdminSubscriptionScreen(),
                                ),
                              ).then((_) => _loadUserData());
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: BooyahTheme.yellow.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: BooyahTheme.yellow.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Text(
                                'PERBARUI',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    _menuGroup('AKUN', [
                      (
                        Icons.person_outline,
                        'Edit Profil',
                        () {
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          ).then((_) => _loadUserData());
                        }
                      ),
                      (
                        Icons.account_balance_wallet,
                        'Rekening & E-Wallet',
                        () {
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => const RekeningEwalletScreen(),
                            ),
                          ).then((_) => _loadUserData());
                        }
                      ),
                      (
                        Icons.monetization_on_outlined,
                        'Tarik Saldo (Cashout)',
                        () {
                          _checkAndShowCashoutSheet();
                        }
                      ),
                      (
                        Icons.receipt_long,
                        'Riwayat Pembayaran',
                        () {
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => const RiwayatPembayaranScreen(),
                            ),
                          );
                        }
                      ),
                      (
                        Icons.help_outline,
                        'Bantuan & FAQ',
                        () {
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => const BantuanFaqScreen(),
                            ),
                          );
                        }
                      ),
                      (
                        Icons.notifications_none,
                        'Notifikasi',
                        () {
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => const NotificationScreen(),
                            ),
                          );
                        }
                      ),
                    ], ctx),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(
                          ctx, 
                          AppRoutes.homeForRole(UserRole.peserta), 
                          (route) => false,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: BooyahTheme.maroon.withValues(alpha: 0.08),
                          border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.person, color: BooyahTheme.maroonB, size: 18),
                          SizedBox(width: 8),
                          Text('KEMBALI KE MODE PESERTA', style: TextStyle(fontSize: 14, color: BooyahTheme.maroonB, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _logout(ctx),
                      child: Container(
                        width: double.infinity, padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: BooyahTheme.red.withValues(alpha: 0.08),
                          border: Border.all(color: BooyahTheme.red.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.logout, color: BooyahTheme.red, size: 18),
                          SizedBox(width: 8),
                          Text('KELUAR', style: TextStyle(fontSize: 14, color: BooyahTheme.red, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = _getAvatarUrl();

    return GestureDetector(
      onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BooyahTheme.maroon,
              border: Border.all(
                color: BooyahTheme.yellow.withValues(alpha: 0.6),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: BooyahTheme.yellow.withValues(alpha: 0.2),
                  blurRadius: 16,
                ),
              ],
            ),
            child: ClipOval(
              child: _uploadingPhoto
                  ? Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: BooyahTheme.yellow,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Text('🔥', style: TextStyle(fontSize: 36))),
                        )
                      : const Center(child: Text('🔥', style: TextStyle(fontSize: 36))),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: BooyahTheme.yellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 12,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    const separator = '.';
    final parts = amount.toString().split('');
    final result = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) {
        result.write(separator);
      }
      result.write(parts[i]);
    }
    return 'Rp ${result.toString()}';
  }

  Future<void> _checkAndShowCashoutSheet() async {
    if (_adminBigId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data profil admin belum dimuat sepenuhnya.')),
      );
      return;
    }

    setState(() => _loading = true);
    BankAccountModel? primaryAccount;
    try {
      primaryAccount = await user_svc.UserService.getPrimaryBankAccount(_adminBigId.toString());
    } catch (e) {
      debugPrint('Error getting primary bank account: $e');
    } finally {
      setState(() => _loading = false);
    }

    if (primaryAccount == null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: BooyahTheme.card,
            title: const Text(
              'REKENING BELUM DIATUR',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            content: const Text(
              'Anda harus mengatur Rekening & E-Wallet utama terlebih dahulu sebelum melakukan penarikan saldo.',
              style: TextStyle(fontSize: 12, color: BooyahTheme.textSec),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('BATAL', style: TextStyle(color: BooyahTheme.textMuted)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RekeningEwalletScreen(),
                    ),
                  ).then((_) => _loadUserData());
                },
                style: ElevatedButton.styleFrom(backgroundColor: BooyahTheme.yellow),
                child: const Text('ATUR REKENING', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        _showCashoutSheet(primaryAccount);
      }
    }
  }

  void _showCashoutSheet(BankAccountModel primaryAccount) {
    final amountCtrl = TextEditingController();
    bool isSubmitting = false;
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BooyahTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final int amount = int.tryParse(amountCtrl.text.replaceAll('.', '')) ?? 0;
          
          void validateAmount(String val) {
            final parsed = int.tryParse(val.replaceAll('.', '')) ?? 0;
            if (parsed == 0) {
              errorText = null;
            } else if (parsed < 10000) {
              errorText = 'Minimal penarikan adalah Rp 10.000';
            } else if (parsed > _adminBalance) {
              errorText = 'Saldo tidak mencukupi';
            } else {
              errorText = null;
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(modalCtx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TARIK SALDO ADMIN',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: BooyahTheme.textMuted, size: 18),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Destination Card
                const Text(
                  'REKENING TUJUAN',
                  style: TextStyle(fontSize: 10, color: BooyahTheme.textMuted, letterSpacing: 0.8),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        primaryAccount.bankType == BankType.bank
                            ? Icons.account_balance_rounded
                            : Icons.phone_android_rounded,
                        color: BooyahTheme.yellow,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              primaryAccount.bankName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${primaryAccount.accountNumber} a.n. ${primaryAccount.accountName}',
                              style: const TextStyle(fontSize: 11, color: BooyahTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Available Balance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Saldo Tersedia:',
                      style: TextStyle(fontSize: 12, color: BooyahTheme.textSec),
                    ),
                    Text(
                      _formatCurrency(_adminBalance),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: BooyahTheme.yellow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sedang Diproses:',
                      style: TextStyle(fontSize: 11, color: BooyahTheme.textMuted),
                    ),
                    Text(
                      _formatCurrency(_totalProcessing),
                      style: const TextStyle(
                        fontSize: 11,
                        color: BooyahTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sudah Ditarik:',
                      style: TextStyle(fontSize: 11, color: BooyahTheme.textMuted),
                    ),
                    Text(
                      _formatCurrency(_totalWithdrawn),
                      style: const TextStyle(
                        fontSize: 11,
                        color: BooyahTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pendapatan:',
                      style: TextStyle(fontSize: 11, color: BooyahTheme.textMuted),
                    ),
                    Text(
                      _formatCurrency(_totalEarnings),
                      style: const TextStyle(
                        fontSize: 11,
                        color: BooyahTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount Input
                const Text(
                  'NOMINAL PENARIKAN (IDR)',
                  style: TextStyle(fontSize: 10, color: BooyahTheme.textMuted, letterSpacing: 0.8),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Masukkan nominal...',
                    hintStyle: const TextStyle(fontSize: 14, color: Colors.white24),
                    errorText: errorText,
                    errorStyle: const TextStyle(color: BooyahTheme.red, fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: BooyahTheme.yellow),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: BooyahTheme.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: BooyahTheme.red),
                    ),
                  ),
                  onChanged: (val) {
                    String clean = val.replaceAll('.', '');
                    if (clean.isEmpty) {
                      amountCtrl.text = '';
                      setModalState(() {
                        errorText = null;
                      });
                      return;
                    }
                    final numVal = int.tryParse(clean) ?? 0;
                    final formatted = _formatNumber(numVal);
                    
                    amountCtrl.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                    
                    setModalState(() {
                      validateAmount(formatted);
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Quick buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _quickAmountButton('50.000', () {
                      if (_adminBalance >= 50000) {
                        amountCtrl.text = '50.000';
                        setModalState(() {
                          validateAmount('50.000');
                        });
                      }
                    }, setModalState),
                    _quickAmountButton('100.000', () {
                      if (_adminBalance >= 100000) {
                        amountCtrl.text = '100.000';
                        setModalState(() {
                          validateAmount('100.000');
                        });
                      }
                    }, setModalState),
                    _quickAmountButton('200.000', () {
                      if (_adminBalance >= 200000) {
                        amountCtrl.text = '200.000';
                        setModalState(() {
                          validateAmount('200.000');
                        });
                      }
                    }, setModalState),
                    _quickAmountButton('Tarik Semua', () {
                      final all = _formatNumber(_adminBalance);
                      amountCtrl.text = all;
                      setModalState(() {
                        validateAmount(all);
                      });
                    }, setModalState),
                  ],
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSubmitting || errorText != null || amount < 10000 || amount > _adminBalance
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            setModalState(() {
                              isSubmitting = true;
                            });

                            try {
                              await AdminService.requestAdminCashout(
                                adminId: _adminBigId!,
                                amount: amount,
                                bankName: primaryAccount.bankName,
                                accountNumber: primaryAccount.accountNumber,
                                accountName: primaryAccount.accountName,
                              );

                              if (!context.mounted) return;
                              Navigator.pop(modalCtx);
                              _showSuccessDialog(amount, primaryAccount);
                              _loadUserData();
                            } catch (e) {
                              debugPrint('Error cashout: $e');
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Gagal melakukan penarikan: $e'),
                                  backgroundColor: BooyahTheme.red,
                                ),
                              );
                            } finally {
                              setModalState(() {
                                isSubmitting = false;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BooyahTheme.yellow,
                      disabledBackgroundColor: BooyahTheme.yellow.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'KIRIM CASHOUT',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: Colors.black,
                            ),
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

    String _formatNumber(int val) {
      const separator = '.';
      final parts = val.toString().split('');
      final result = StringBuffer();
      for (int i = 0; i < parts.length; i++) {
        if (i > 0 && (parts.length - i) % 3 == 0) {
          result.write(separator);
        }
        result.write(parts[i]);
      }
      return result.toString();
    }

  Widget _quickAmountButton(String label, VoidCallback onTap, StateSetter setModalState) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  void _showSuccessDialog(int amount, BankAccountModel account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BooyahTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Column(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 48),
            SizedBox(height: 12),
            Text(
              'PENARIKAN BERHASIL',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Penarikan saldo Anda sebesar ${_formatCurrency(amount)} telah berhasil diproses secara instan!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: BooyahTheme.textSec),
            ),
            const SizedBox(height: 12),
            Text(
              'Tujuan: ${account.bankName} (${account.accountNumber})',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: BooyahTheme.textMuted),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: BooyahTheme.yellow,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: const Text(
                'TUTUP',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String v, String l) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(children: [
      Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: BooyahTheme.yellow)),
      Text(l, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: BooyahTheme.textMuted)),
    ]),
  );

  Widget _menuGroup(String title, List<(IconData, String, VoidCallback?)> items, BuildContext ctx) =>
      Container(
        decoration: BoxDecoration(
          color: BooyahTheme.card, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Text(title, style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
          ),
          ...items.map((m) => InkWell(
            onTap: m.$3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Icon(m.$1, color: BooyahTheme.yellow, size: 18),
                const SizedBox(width: 12),
                Text(m.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: BooyahTheme.textSec)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: BooyahTheme.textMuted, size: 16),
              ]),
            ),
          )),
        ]),
      );
}
