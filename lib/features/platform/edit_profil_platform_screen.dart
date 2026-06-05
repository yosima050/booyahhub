import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart'; 
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
  bool _uploadingPhoto = false; 
  String? _currentImageUrl; // Menampung URL foto profil aktif

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
          _currentImageUrl = userData['avatar_url']?.toString(); // Tarik status URL foto dari DB
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

      // Upload berkas biner gambar ke Supabase Storage bucket "avatars"
      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            file.bytes!,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // Simpan langsung perubahan URL ke tabel users berdasarkan uuid
      await Supabase.instance.client
          .from('users')
          .update({'avatar_url': publicUrl})
          .eq('uuid', user.id);

      setState(() {
        // Manipulasi URL dengan timestamp unik agar image engine Flutter dipaksa merender gambar terbaru
        _currentImageUrl = "$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}"; 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil admin berhasil diperbarui!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Upload photo error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload foto: $e'), backgroundColor: BooyahTheme.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
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
        'avatar_url': _currentImageUrl, 
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client.from('users').update(updateData).eq('uuid', user.id);

      // Trigger Simpan ke Audit Log Sistem
      await Supabase.instance.client.from('audit_logs').insert({
        'actor_role': 'platform',
        'action': 'UPDATE_PLATFORM_PROFILE',
        'description': 'Super Admin mengubah informasi data utama profil.',
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
                        onTap: _uploadingPhoto ? null : _pickAndUploadPhoto, // Langsung memicu FilePicker galeri
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
                                child: _uploadingPhoto
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(45),
                                        child: (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                                            ? Image.network(
                                                _currentImageUrl!,
                                                fit: BoxFit.cover,
                                                width: 90,
                                                height: 90,
                                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_rounded, size: 42, color: Colors.white),
                                              )
                                            : const Icon(Icons.person_rounded, size: 42, color: Colors.white),
                                      ),
                              ),
                            ),
                            if (!_uploadingPhoto)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: BooyahTheme.card,
                                  child: Icon(Icons.camera_alt_rounded, size: 14, color: BooyahTheme.maroonGlow.withAlpha(220)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('SUPER OWNER PLATFORM', style: TextStyle(fontFamily: 'Orbitron', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    const Text('KETUK FOTO UNTUK MENGGANTI FOTO PROFIL DARI GALERI', style: TextStyle(fontSize: 9, color: BooyahTheme.maroonGlow, fontWeight: FontWeight.bold)),
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
