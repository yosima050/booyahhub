import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/auth_service.dart';
import '../../services/supabase_service.dart' show UserService;

class EditProfilPlatformScreen extends StatefulWidget {
  const EditProfilPlatformScreen({super.key});

  @override
  State<EditProfilPlatformScreen> createState() => _EditProfilPlatformScreenState();
}

class _EditProfilPlatformScreenState extends State<EditProfilPlatformScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  // DAFTAR KOLEKSI AVATAR IKON SISTEM (Hanya simpan angka indeksnya di DB)
  final List<IconData> _avatarCollection = [
    Icons.apartment_rounded,      // Indeks 0 (Gedung bawaan)
    Icons.admin_panel_settings,   // Indeks 1
    Icons.gavel_rounded,          // Indeks 2
    Icons.insights_rounded,       // Indeks 3
    Icons.hub_rounded,            // Indeks 4
    Icons.terminal_rounded,       // Indeks 5
  ];

  int _selectedAvatarIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPlatformData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPlatformData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final userData = await UserService.getUserProfile(user.id);

      if (mounted) {
        setState(() {
          _nameController.text = userData['name']?.toString() ?? '';
          _usernameController.text = userData['username']?.toString() ?? '';
          _phoneController.text = userData['phone']?.toString() ?? '';
          // Ambil indeks avatar dari kolom 'avatar_index' di tabel users
          _selectedAvatarIndex = userData['avatar_index'] as int? ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading platform profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) setState(() => _isSaving = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'avatar_index': _selectedAvatarIndex, // Hanya menyimpan angka int saja, enteng banget!
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client.from('users').update(updateData).eq('uuid', user.id);

      // Trigger Audit Log
      await Supabase.instance.client.from('audit_logs').insert({
        'actor_role': 'platform',
        'action': 'UPDATE_PLATFORM_PROFILE',
        'description': 'Super Admin mengubah informasi profil dan mengganti ikon avatar.',
        'entity_type': 'users',
      });

      AuthService().updateName(_nameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil platform berhasil diperbarui!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan perubahan: $e'), backgroundColor: BooyahTheme.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: BooyahTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PILIH AVATAR SISTEM',
                    style: TextStyle(fontFamily: 'Orbitron', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pilih ikon identitas visual master platform yang disediakan sistem',
                    style: TextStyle(fontSize: 10, color: BooyahTheme.textMuted),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _avatarCollection.length,
                    itemBuilder: (context, index) {
                      final bool isSelected = _selectedAvatarIndex == index;
                      return InkWell(
                        onTap: () {
                          setModalState(() => _selectedAvatarIndex = index);
                          setState(() => _selectedAvatarIndex = index);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? BooyahTheme.maroonGlow.withAlpha(40) : BooyahTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? BooyahTheme.maroonGlow : BooyahTheme.maroonGlow.withAlpha(20),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            _avatarCollection[index],
                            color: isSelected ? Colors.white : BooyahTheme.textMuted,
                            size: 28,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BooyahTheme.surface,
      appBar: AppBar(
        title: const Text('EDIT PROFIL PLATFORM', style: TextStyle(fontFamily: 'Orbitron', fontSize: 13, fontWeight: FontWeight.bold)),
        backgroundColor: BooyahTheme.card,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: BooyahTheme.maroonGlow))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _showAvatarPicker,
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: BooyahTheme.maroonGlow.withAlpha(80), blurRadius: 20, spreadRadius: 2)
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: BooyahTheme.maroonGlow,
                                child: Icon(_avatarCollection[_selectedAvatarIndex], size: 42, color: Colors.white),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: BooyahTheme.card,
                                child: Icon(Icons.edit_rounded, size: 14, color: BooyahTheme.maroonGlow.withAlpha(220)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('SUPER OWNER PLATFORM', style: TextStyle(fontFamily: 'Orbitron', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    const Text('KETUK FOTO UNTUK MENGGANTI AVATAR', style: TextStyle(fontSize: 9, color: BooyahTheme.maroonGlow, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: BooyahTheme.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: BooyahTheme.maroonGlow.withAlpha(30)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('INFORMASI UTAMA PLATFORM', style: TextStyle(fontFamily: 'Orbitron', fontSize: 10, fontWeight: FontWeight.bold, color: BooyahTheme.textMuted, letterSpacing: 1)),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _nameController,
                            label: 'Nama Pengelola / Owner',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _usernameController,
                            label: 'Username Sistem',
                            icon: Icons.alternate_email_rounded,
                            validator: (v) {
                              if (v != null && v.contains(' ')) return 'Username tidak boleh mengandung spasi';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Nomor WhatsApp Internal',
                            icon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(colors: [BooyahTheme.maroon, BooyahTheme.maroonGlow]),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('SIMPAN PERUBAHAN PROFIL', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Orbitron', fontSize: 12, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 13, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: BooyahTheme.textMuted, fontSize: 11),
        prefixIcon: Icon(icon, color: BooyahTheme.maroonGlow, size: 18),
        filled: true,
        fillColor: BooyahTheme.surface.withAlpha(150),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: BooyahTheme.maroonGlow, width: 1.5), borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: BooyahTheme.maroonGlow.withAlpha(25)), borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
