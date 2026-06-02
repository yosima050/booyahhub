import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bantuan_faq_screen.dart';
import 'tentang_aplikasi_screen.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../core/auth_service.dart';
import '../../shared/models/models.dart';
import '../../services/supabase_service.dart' show UserService;
import 'edit_profile_screen.dart'; // Pastikan import screen baru kamu di sini

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  bool _uploadingPhoto = false;
  RealtimeChannel? _profileChannel;

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
        .channel('profile_sync_peserta_${user.id}')
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
            debugPrint('Realtime user profile updated: ${payload.newRecord}');
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

  // ── Ambil kata pertama dari email (sebelum titik atau @) ──────────────────
  String _usernameFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'Player';
    final local = email.split('@').first;
    final word = local.split(RegExp(r'[._\-+]')).first;
    return word.isNotEmpty
        ? '${word[0].toUpperCase()}${word.substring(1)}'
        : 'Player';
  }

  // ── Ambil avatar URL (dari profiles atau Google OAuth) ────────────────────
  String? _getAvatarUrl() {
    final fromProfile = _userData?['avatar_url'] as String?;
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;

    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['avatar_url'] as String? ??
        user?.userMetadata?['picture'] as String?;
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userData = await UserService.getUserProfile(user.id);
        if (mounted) {
          setState(() {
            _userData = userData;
          });
        }

        // Gunakan bigint ID (dikirim sebagai string) untuk menghindari error syntax bigint
        final userBigId = userData['id']?.toString();
        if (userBigId != null) {
          final stats = await UserService.getUserStats(userBigId);
          if (mounted) {
            setState(() {
              _stats = stats;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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

      if (mounted) {
        setState(() {
          _userData = {...?_userData, 'avatar_url': publicUrl};
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
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

  // ── Widget foto profil ─────────────────────────────────────────────────────
  Widget _buildAvatar() {
    final avatarUrl = _getAvatarUrl();

    return GestureDetector(
      onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: BooyahTheme.maroon.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: BooyahTheme.maroon),
              boxShadow: [
                BoxShadow(
                  color: BooyahTheme.maroon.withValues(alpha: 0.5),
                  blurRadius: 20,
                ),
              ],
            ),
            child: ClipOval(
              child: _uploadingPhoto
                  ? Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : avatarUrl != null && avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(
                        child: Text('🐺', style: TextStyle(fontSize: 40)),
                      ),
                    )
                  : const Center(
                      child: Text('🐺', style: TextStyle(fontSize: 40)),
                    ),
            ),
          ),
          // Badge kamera pojok kanan bawah
          if (!_uploadingPhoto)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: BooyahTheme.maroon,
                  shape: BoxShape.circle,
                  border: Border.all(color: BooyahTheme.bg, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _logout(BuildContext ctx) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: BooyahTheme.card,
      title: const Text(
        'LOGOUT',
        style: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: const Text(
        'Kamu yakin ingin keluar?',
        style: TextStyle(fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            'BATAL',
            style: TextStyle(color: BooyahTheme.textMuted),
          ),
        ),
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
    final isAdmin =
        AuthService().role == UserRole.admin ||
        _userData?['role']?.toString().toLowerCase() == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('PROFIL')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB22222)),
            )
          : RefreshIndicator(
              onRefresh: _loadUserData,
              color: BooyahTheme.maroon,
              backgroundColor: BooyahTheme.card,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ── Hero Section ─────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            BooyahTheme.maroonD.withValues(alpha: 0.8),
                            BooyahTheme.bg,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildAvatar(),
                          const SizedBox(height: 12),

                          // Nama utama pengguna
                          Text(
                            (_userData?['name'] != null && (_userData?['name'] as String).trim().isNotEmpty)
                                ? _userData!['name'] as String
                                : _usernameFromEmail(Supabase.instance.client.auth.currentUser?.email),
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          // Username handle dari database jika diisi
                          if (_userData?['username'] != null && (_userData?['username'] as String).trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '@${_userData!['username']}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: BooyahTheme.gold,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],

                          // Nama tim scrim · role
                          Text(
                            '${_userData?['team_name'] ?? 'Belum ada tim'} · ${_userData?['role'] ?? 'Peserta'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: BooyahTheme.textMuted,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _stat(
                                '${_stats['total_scrims'] ?? 0}',
                                'SCRIM\nDIIKUTI',
                              ),
                              Container(
                                width: 1,
                                height: 36,
                                color: BooyahTheme.maroon.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              _stat(
                                '${_stats['total_kills'] ?? 0}',
                                'TOTAL\nKILLS',
                              ),
                              Container(
                                width: 1,
                                height: 36,
                                color: BooyahTheme.maroon.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              _stat(
                                _fmtRupiah(_stats['total_rewards'] ?? 0),
                                'HADIAH\nDITERIMA',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Menu Section ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _menuGroup('SCRIM', [
                            _MenuItem(
                              Icons.history,
                              'Riwayat Scrim',
                              () => Navigator.pushNamed(ctx, AppRoutes.riwayat),
                            ),
                            _MenuItem(
                              Icons.emoji_events,
                              'Klaim Hadiah',
                              () => Navigator.pushNamed(
                                ctx,
                                AppRoutes.klaimHadiah,
                              ),
                            ),
                            _MenuItem(
                              Icons.pending_actions,
                              'Status Pendaftaran',
                              () => Navigator.pushNamed(
                                ctx,
                                AppRoutes.statusPendaftaran,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          _menuGroup('AKUN', [
                            _MenuItem(Icons.person_outline, 'Edit Profil', () {
                              Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              ).then((_) => _loadUserData());
                            }),
                            _MenuItem(
                              Icons.account_balance_wallet,
                              'Rekening & E-Wallet',
                              null,
                            ),
                            _MenuItem(
                              Icons.receipt_long,
                              'Riwayat Pembayaran',
                              null,
                            ),
                          ]),

                          // Conditional Admin Section
                          if (isAdmin) ...[
                            const SizedBox(height: 10),
                            _menuGroup(
                              'ADMINISTRATOR',
                              [
                                _MenuItem(
                                  Icons.admin_panel_settings_rounded,
                                  'KEMBALI KE PROFIL ADMIN',
                                  () {
                                    Navigator.pushNamedAndRemoveUntil(
                                      ctx,
                                      AppRoutes.adminShell,
                                      (route) => false,
                                    );
                                  },
                                  iconColor: BooyahTheme.yellow,
                                ),
                              ],
                              borderColor: BooyahTheme.yellow.withValues(
                                alpha: 0.35,
                              ),
                              titleColor: BooyahTheme.yellow,
                            ),
                          ],

                          const SizedBox(height: 10),
                          _menuGroup('LAINNYA', [
                            _MenuItem(
                              Icons.help_outline,
                              'Bantuan & FAQ',
                              () => Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                  builder: (_) => const BantuanFaqScreen(),
                                ),
                              ),
                            ),
                            _MenuItem(
                              Icons.info_outline,
                              'Tentang Aplikasi',
                              () => Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                  builder: (_) => const TentangAplikasiScreen(),
                                ),
                              ),
                            ),
                            _MenuItem(
                              Icons.logout,
                              'Keluar',
                              () => _logout(ctx),
                              isRed: true,
                            ),
                          ]),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmtRupiah(int amount) {
    if (amount == 0) return 'Rp0';

    final chars = amount.toString().split('').reversed.toList();

    String result = '';

    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) result += '.';
      result += chars[i];
    }

    return 'Rp${result.split('').reversed.join('')}';
  }

  Widget _stat(String val, String label) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          children: [
            Text(
              val,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: BooyahTheme.maroonB,
              ),
            ),

            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: BooyahTheme.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );

  Widget _menuGroup(
    String title,
    List<_MenuItem> items, {
    Color? borderColor,
    Color? titleColor,
  }) => Container(
    decoration: BoxDecoration(
      color: BooyahTheme.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: borderColor ?? BooyahTheme.maroon.withValues(alpha: 0.2),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: titleColor ?? BooyahTheme.textMuted,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...items.map(
          (m) => Column(
            children: [
              InkWell(
                onTap: m.onTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        m.icon,
                        color: m.isRed
                            ? BooyahTheme.red
                            : (m.iconColor ?? BooyahTheme.maroonB),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        m.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: m.isRed
                              ? BooyahTheme.red
                              : BooyahTheme.textSec,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        color: m.isRed
                            ? BooyahTheme.red.withValues(alpha: 0.5)
                            : (m.iconColor?.withValues(alpha: 0.5) ?? BooyahTheme.textMuted),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              if (m != items.last)
                Divider(
                  height: 1,
                  indent: 46,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isRed;
  final Color? iconColor;

  const _MenuItem(
    this.icon,
    this.label,
    this.onTap, {
    this.isRed = false,
    this.iconColor,
  });

  @override
  bool operator ==(Object other) =>
      other is _MenuItem && other.label == label;

  @override
  int get hashCode => label.hashCode;
}