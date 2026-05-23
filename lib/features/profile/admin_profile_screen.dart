import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../core/auth_service.dart';
import '../../shared/models/models.dart';
import '../../services/supabase_service.dart' show UserService;
import 'edit_profile_screen.dart';
import 'bantuan_faq_screen.dart';

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
        setState(() {
          _userData = userData;
        });
      }
    } catch (e) {
      debugPrint('Error loading admin profile: $e');
    } finally {
      setState(() => _loading = false);
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
      setState(() => _uploadingPhoto = false);
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
          onPressed: () {
            AuthService().logout();
            Navigator.pushNamedAndRemoveUntil(ctx, AppRoutes.login, (r) => false);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFIL ADMIN'),
        actions: [Chip(
          label: const Text('ADMIN', style: TextStyle(fontSize: 9)),
          backgroundColor: BooyahTheme.yellow.withValues(alpha: 0.15),
          labelStyle: const TextStyle(color: BooyahTheme.yellow, fontWeight: FontWeight.w700),
        ), const SizedBox(width: 8)],
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
                        color: BooyahTheme.yellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: BooyahTheme.yellow.withValues(alpha: 0.4)),
                      ),
                      child: const Text('★ ADMIN PREMIUM', style: TextStyle(
                        fontSize: 10, color: BooyahTheme.yellow, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _stat('42', 'SCRIM\nDIBUAT'),
                      Container(width: 1, height: 32, color: BooyahTheme.maroon.withValues(alpha: 0.4)),
                      _stat('834', 'TIM\nDIDAFTAR'),
                      Container(width: 1, height: 32, color: BooyahTheme.maroon.withValues(alpha: 0.4)),
                      _stat('97%', 'RATING\nVERIF'),
                    ]),
                  ]),
                ),

                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: BooyahTheme.yellow.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: BooyahTheme.yellow.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Text('⭐', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Premium Aktif', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          Text('28 hari tersisa', style: TextStyle(fontSize: 10, color: BooyahTheme.yellow)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: BooyahTheme.yellow.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: BooyahTheme.yellow.withValues(alpha: 0.4)),
                          ),
                          child: const Text('PERBARUI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                        ),
                      ]),
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
