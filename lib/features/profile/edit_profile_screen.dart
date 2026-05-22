import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/auth_service.dart';
import '../../services/supabase_service.dart' show UserService;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller Form
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ffIdController = TextEditingController();
  final _teamNameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _userRole = 'peserta'; // Default role, akan diupdate dari DB
  int? _userBigId;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _ffIdController.dispose();
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Mengambil data profile dari backend/service kamu
      final userData = await UserService.getUserProfile(user.id);

      setState(() {
        _userBigId = int.tryParse(userData['id']?.toString() ?? '');
        _userRole = userData['role']?.toString().toLowerCase() ?? 'peserta';
        _nameController.text = userData['name']?.toString() ?? '';
        _usernameController.text = userData['username']?.toString() ?? '';
        _phoneController.text = userData['phone']?.toString() ?? '';
        _ffIdController.text = userData['ff_id']?.toString() ?? '';
        _teamNameController.text = userData['team_name']?.toString() ?? '';
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Map data yang akan diupdate secara umum
      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim().isEmpty
            ? null
            : _usernameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Jika yang login adalah PESERTA, sertakan data Game Free Fire ke dalam query update
      if (_userRole == 'peserta') {
        updateData['ff_id'] = _ffIdController.text.trim().isEmpty
            ? null
            : _ffIdController.text.trim();
        updateData['team_name'] = _teamNameController.text.trim().isEmpty
            ? null
            : _teamNameController.text.trim();
      }

      // Jalankan query ke Supabase
      await Supabase.instance.client
          .from('users')
          .update(updateData)
          .eq('uuid', user.id);

      // Jika role adalah admin, update juga tabel admin_profiles
      if (_userRole == 'admin' && _userBigId != null) {
        await Supabase.instance.client
            .from('admin_profiles')
            .update({'display_name': _nameController.text.trim()})
            .eq('user_id', _userBigId!);
      }

      // Update local memory cache so other screens can rebuild with new name
      AuthService().updateName(_nameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );
        Navigator.pop(context); // Kembali ke screen sebelumnya
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan perubahan: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _userRole == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAdmin ? 'EDIT PROFIL ADMIN' : 'EDIT PROFIL PESERTA',
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: BooyahTheme.card,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: BooyahTheme.maroon),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Indikator Role Akun
                    _buildRoleBadge(isAdmin),
                    const SizedBox(height: 20),

                    _buildSectionTitle('INFORMASI DASAR AKUN'),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _nameController,
                      label: 'Nama Lengkap',
                      icon: Icons.person,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.alternate_email,
                      validator: (v) {
                        if (v != null && v.contains(' ')) {
                          return 'Username tidak boleh mengandung spasi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _phoneController,
                      label: 'Nomor WhatsApp / HP',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),

                    // Conditional Rendering: Field ini hanya muncul jika user adalah PESERTA
                    if (!isAdmin) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('DATA GAME & TEAM (KHUSUS PESERTA)'),
                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _ffIdController,
                        label: 'UID Free Fire',
                        icon: Icons.sports_esports,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _teamNameController,
                        label: 'Nama Tim / Guild',
                        icon: Icons.group,
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAdmin
                              ? BooyahTheme.yellow
                              : BooyahTheme.maroon,
                          foregroundColor: isAdmin
                              ? Colors.black
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: isAdmin ? Colors.black : Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'SIMPAN PERUBAHAN',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                  color: isAdmin ? Colors.black : Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRoleBadge(bool isAdmin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAdmin
            ? BooyahTheme.yellow.withValues(alpha: 0.1)
            : BooyahTheme.maroon.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAdmin
              ? BooyahTheme.yellow
              : BooyahTheme.maroon.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.emoji_events,
            color: isAdmin ? BooyahTheme.yellow : BooyahTheme.maroonB,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            isAdmin
                ? 'LOGGED IN AS: ADMINISTRATOR'
                : 'LOGGED IN AS: PESERTA SCRIM',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isAdmin ? BooyahTheme.yellow : BooyahTheme.maroonB,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: BooyahTheme.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: BooyahTheme.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: BooyahTheme.maroonB, size: 20),
        filled: true,
        fillColor: BooyahTheme.card,
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: BooyahTheme.maroon),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: BooyahTheme.maroon.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: BooyahTheme.red),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: BooyahTheme.red),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
