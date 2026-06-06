import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../services/supabase_service.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../config/supabase_config.dart'; 

class ManajemenAkunScreen extends StatefulWidget {
  const ManajemenAkunScreen({super.key});

  @override
  State<ManajemenAkunScreen> createState() => _ManajemenAkunScreenState();
}

class _ManajemenAkunScreenState extends State<ManajemenAkunScreen> {
  late List<Map<String, dynamic>> _users = [];
  int _filterIdx = 0;
  final _filters = ['SEMUA', 'PESERTA', 'ADMIN', 'SUSPEND'];
  bool _isLoading = true;
  String? _error;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _searchController;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _searchController = TextEditingController();
    _loadUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
      final search = _searchController.text.trim();
      final users = await PlatformService.getUsers(search: search.isNotEmpty ? search : null);
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      debugPrint('Error loading users: $e');
    }
  }

  List<Map<String, dynamic>> get _filtered {
    switch (_filterIdx) {
      case 1:
        return _users
            .where((u) => u['role'] == 'peserta' && !(u['is_suspended'] as bool? ?? false))
            .toList();
      case 2:
        return _users.where((u) => u['role'] == 'admin').toList();
      case 3:
        return _users.where((u) => (u['is_suspended'] as bool? ?? false)).toList();
      default:
        return _users;
    }
  }

  void _toggleSuspend(Map<String, dynamic> u) {
    if (u['role'] == 'platform') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.gpp_bad, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Expanded(child: Text('Akses Ditolak: Tidak bisa suspend akun Platform!')),
            ],
          ),
          backgroundColor: BooyahTheme.red,
        ),
      );
      return;
    }

    final currentStatus = u['is_suspended'] as bool? ?? false;
    final newStatus = !currentStatus;
    final reasonController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: BooyahTheme.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(newStatus ? Icons.block : Icons.check_circle, color: BooyahTheme.yellow, size: 18),
              const SizedBox(width: 8),
              Text(
                newStatus ? 'SUSPEND AKUN' : 'AKTIFKAN AKUN',
                style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 15, fontWeight: FontWeight.bold, color: BooyahTheme.yellow),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                newStatus 
                    ? 'Apakah Anda yakin ingin menangguhkan akun "${u['name']}"?'
                    : 'Apakah Anda yakin ingin mengaktifkan kembali akun "${u['name']}"?',
                style: const TextStyle(fontSize: 12, color: BooyahTheme.textPri),
              ),
              if (newStatus) ...[
                const SizedBox(height: 16),
                const Text('Alasan Penangguhan:', style: TextStyle(fontSize: 11, color: BooyahTheme.textMuted, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Tulis alasan di sini...',
                    hintStyle: const TextStyle(color: BooyahTheme.textMuted, fontSize: 11),
                    filled: true,
                    fillColor: BooyahTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BooyahTheme.maroon, width: 0.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: BooyahTheme.maroon.withValues(alpha: 0.3), width: 0.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BooyahTheme.yellow, width: 1)),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                  style: const TextStyle(fontSize: 11, color: BooyahTheme.textPri),
                ),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('BATAL', style: TextStyle(color: BooyahTheme.textMuted, fontSize: 12)),
            ),
            TextButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (newStatus && reason.isEmpty) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text('Harap isi alasan suspend'),
                        ],
                      ),
                      backgroundColor: BooyahTheme.red,
                    ),
                  );
                  return;
                }
                try {
                  await PlatformService.toggleSuspend(u['id'], newStatus, reason: newStatus ? reason : null);
                  await _loadUsers();
                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(newStatus ? Icons.block : Icons.check_circle, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(newStatus
                                ? 'Akun ${u['name']} disuspend.'
                                : 'Akun ${u['name']} diaktifkan.'),
                          ),
                        ],
                      ),
                      backgroundColor: newStatus ? BooyahTheme.red : BooyahTheme.green,
                    ),
                  );
                } catch (e) {
                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Error: $e')),
                        ],
                      ),
                      backgroundColor: BooyahTheme.red,
                    ),
                  );
                }
              },
              child: Text(newStatus ? 'SUSPEND' : 'AKTIFKAN', style: const TextStyle(color: BooyahTheme.red, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteUser(Map<String, dynamic> u) {
    if (u['role'] == 'platform') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.gpp_bad, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Expanded(child: Text('Akses Ditolak: Tidak bisa menghapus akun Platform!')),
            ],
          ),
          backgroundColor: BooyahTheme.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BooyahTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: BooyahTheme.red, size: 18),
            const SizedBox(width: 8),
            const Text('HAPUS PENGGUNA',
                style: TextStyle(fontFamily: 'Rajdhani', fontSize: 15, fontWeight: FontWeight.bold, color: BooyahTheme.red)),
          ],
        ),
        content: Text(
            'Apakah Anda yakin ingin menghapus akun "${u['name']}"? Tindakan ini akan menghapus akun secara lunak (soft delete) dan tidak akan ditampilkan lagi.',
            style: const TextStyle(fontSize: 12, color: BooyahTheme.textPri)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL', style: TextStyle(color: BooyahTheme.textMuted, fontSize: 12)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await PlatformService.deleteUser(u['id']);
                await _loadUsers();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Akun ${u['name']} berhasil dihapus.')),
                        ],
                      ),
                      backgroundColor: BooyahTheme.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Error: $e')),
                        ],
                      ),
                      backgroundColor: BooyahTheme.red,
                    ),
                  );
                }
              }
            },
            child: const Text('HAPUS', style: TextStyle(color: BooyahTheme.red, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _registerPlatformAccount(String name, String email, String password) async {
    try {
      setState(() => _isRegistering = true);

      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text('Semua field harus diisi'),
                ],
              ),
              backgroundColor: BooyahTheme.red,
            ),
          );
        }
        return;
      }

      if (password.length < 6) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text('Password minimal 6 karakter'),
                ],
              ),
              backgroundColor: BooyahTheme.red,
            ),
          );
        }
        return;
      }

      final isolatedClient = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.anonKey,
      );

      final response = await isolatedClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': 'platform',
        },
      );

      if (response.user != null && mounted) {
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Akun Platform "$name" berhasil didaftarkan!')),
              ],
            ),
            backgroundColor: BooyahTheme.green,
            duration: const Duration(seconds: 2),
          ),
        );

        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: BooyahTheme.red,
          ),
        );
      }
      debugPrint('Error registering platform account: $e');
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  void _showAddPlatformDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isRegistering,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: BooyahTheme.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'TAMBAH STAFF PLATFORM',
            style: TextStyle(fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w700, color: BooyahTheme.yellow),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  enabled: !_isRegistering,
                  decoration: InputDecoration(
                    hintText: 'Nama Lengkap',
                    hintStyle: const TextStyle(color: BooyahTheme.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: BooyahTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BooyahTheme.maroon, width: 0.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: BooyahTheme.maroon.withValues(alpha: 0.3), width: 0.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BooyahTheme.yellow, width: 1)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 12, color: BooyahTheme.textPri),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  enabled: !_isRegistering,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: const TextStyle(color: BooyahTheme.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: BooyahTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BooyahTheme.maroon, width: 0.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: BooyahTheme.maroon.withValues(alpha: 0.3), width: 0.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BooyahTheme.yellow, width: 1)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 12, color: BooyahTheme.textPri),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  enabled: !_isRegistering,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password (minimal 6 karakter)',
                    hintStyle: const TextStyle(color: BooyahTheme.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: BooyahTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BooyahTheme.maroon, width: 0.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: BooyahTheme.maroon.withValues(alpha: 0.3), width: 0.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BooyahTheme.yellow, width: 1)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 12, color: BooyahTheme.textPri),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isRegistering
                  ? null
                  : () {
                      _nameController.clear();
                      _emailController.clear();
                      _passwordController.clear();
                      Navigator.pop(context);
                    },
              child: const Text('BATAL', style: TextStyle(color: BooyahTheme.textMuted)),
            ),
            TextButton(
              onPressed: _isRegistering
                  ? null
                  : () async {
                      setDialogState(() {}); 
                      await _registerPlatformAccount(
                        _nameController.text.trim(),
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      );
                    },
              child: _isRegistering
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(BooyahTheme.yellow)),
                    )
                  : const Text('DAFTARKAN', style: TextStyle(color: BooyahTheme.yellow, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _changeRole(Map<String, dynamic> u) {
    final currentRole = u['role'] as String? ?? 'peserta';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BooyahTheme.card,
        title: Text('Ubah Role – ${u['name']}',
            style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['peserta', 'admin', 'platform'].map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              tileColor: currentRole == r ? BooyahTheme.maroon.withValues(alpha: 0.15) : Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              title: Text(r.toUpperCase(), style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 13)),
              trailing: currentRole == r ? const Icon(Icons.check_circle, color: BooyahTheme.maroonB, size: 18) : null,
              onTap: () async {
                if (currentRole != r) {
                  try {
                    await PlatformService.changeRole(u['id'], r);
                    await _loadUsers();
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Role ${u['name']} diubah ke ${r.toUpperCase()}')),
                          ],
                        ),
                        backgroundColor: BooyahTheme.green,
                      ));
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Error: $e')),
                          ],
                        ),
                        backgroundColor: BooyahTheme.red,
                      ));
                    }
                  }
                }
              },
            ),
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
        appBar: AppBar(
          title: const Text('MANAJEMEN AKUN'),
          automaticallyImplyLeading: false,
          actions: [const SizedBox(width: 8)],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: BooyahTheme.maroonB))
            : _error != null
                ? Center(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: BooyahTheme.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error', style: const TextStyle(color: BooyahTheme.textMuted), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _loadUsers,
                        icon: const Icon(Icons.refresh),
                        label: const Text('COBA LAGI'),
                      ),
                    ],
                  ))
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        color: BooyahTheme.surface,
                        child: Row(children: [
                          _statBadge(Icons.groups, 'TOTAL', '${_users.length}', BooyahTheme.maroonB),
                          const SizedBox(width: 10),
                          _statBadge(Icons.person, 'PESERTA', '${_users.where((u) => u['role'] == 'peserta' && !(u['is_suspended'] as bool? ?? false)).length}', BooyahTheme.green),
                          const SizedBox(width: 10),
                          _statBadge(Icons.admin_panel_settings, 'ADMIN', '${_users.where((u) => u['role'] == 'admin').length}', BooyahTheme.yellow),
                          const SizedBox(width: 10),
                          _statBadge(Icons.block, 'SUSPEND', '${_users.where((u) => (u['is_suspended'] as bool? ?? false)).length}', BooyahTheme.red),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (_) => _loadUsers(),
                          decoration: InputDecoration(
                            hintText: 'Cari nama atau email...',
                            hintStyle: const TextStyle(color: BooyahTheme.textMuted, fontSize: 12),
                            filled: true,
                            fillColor: BooyahTheme.surface,
                            prefixIcon: const Icon(Icons.search, color: BooyahTheme.textMuted, size: 18),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: BooyahTheme.textMuted, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _loadUsers();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BooyahTheme.maroon, width: 0.5)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: BooyahTheme.maroon.withValues(alpha: 0.3), width: 0.5)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BooyahTheme.yellow, width: 1)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 12, color: BooyahTheme.textPri),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          itemCount: _filters.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 6),
                          itemBuilder: (_, i) {
                            final active = _filterIdx == i;
                            return GestureDetector(
                              onTap: () => setState(() => _filterIdx = i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: active ? BooyahTheme.maroon : BooyahTheme.surface,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: active ? BooyahTheme.maroon : BooyahTheme.maroon.withValues(alpha: 0.2)),
                                ),
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Text(_filters[i], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active ? Colors.white : BooyahTheme.textMuted)),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final u = _filtered[i];
                            final isSuspended = u['is_suspended'] as bool? ?? false;
                            final role = u['role'] as String? ?? 'peserta';
                            final roleColor = role == 'admin'
                                ? BooyahTheme.yellow
                                : role == 'platform'
                                    ? BooyahTheme.maroonGlow
                                    : BooyahTheme.green;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSuspended ? BooyahTheme.red.withValues(alpha: 0.05) : BooyahTheme.card,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSuspended ? BooyahTheme.red.withValues(alpha: 0.2) : BooyahTheme.maroon.withValues(alpha: 0.2)),
                              ),
                              child: Row(children: [
                                Icon(
                                  Icons.account_circle, 
                                  size: 32, 
                                  color: isSuspended ? BooyahTheme.textMuted : BooyahTheme.maroonB
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(u['name'] as String? ?? 'Unknown',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          decoration: isSuspended ? TextDecoration.lineThrough : null,
                                          color: isSuspended ? BooyahTheme.textMuted : BooyahTheme.textPri)),
                                  Text(u['email'] as String? ?? '', style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted)),
                                  if (isSuspended && u['suspension_reason'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Alasan: ${u['suspension_reason']}',
                                      style: const TextStyle(fontSize: 9, color: BooyahTheme.red, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ])) ,
                                const SizedBox(width: 6),
                                StatusBadge(
                                  label: isSuspended ? 'SUSPEND' : role.toUpperCase(),
                                  color: isSuspended ? BooyahTheme.red : roleColor,
                                  showDot: false,
                                ),
                                const SizedBox(width: 8),
                                Row(children: [
                                  if (!isSuspended)
                                    _smallBtn(Icons.block, BooyahTheme.red, () => _toggleSuspend(u))
                                  else
                                    _smallBtn(Icons.check_circle, BooyahTheme.green, () => _toggleSuspend(u)),
                                  const SizedBox(width: 4),
                                  if (role != 'platform') ...[
                                    _smallBtn(Icons.swap_horiz, BooyahTheme.yellow, () => _changeRole(u)),
                                    const SizedBox(width: 4),
                                    _smallBtn(Icons.delete_outline, BooyahTheme.red, () => _deleteUser(u)),
                                  ]
                                ]),
                              ]),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddPlatformDialog,
          backgroundColor: BooyahTheme.yellow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          icon: const Icon(Icons.add_moderator, color: Colors.black, size: 20),
          label: const Text(
            'TAMBAH PLATFORM',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 11, fontFamily: 'Rajdhani'),
          ),
        ),
      );

  Widget _smallBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      );

  Widget _statBadge(IconData icon, String label, String val, Color color) => Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 9, color: BooyahTheme.textMuted), textAlign: TextAlign.center),
        ]),
      );
}