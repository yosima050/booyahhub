import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../services/supabase_service.dart';
import '../../shared/models/models.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();
  bool _loading    = false;
  bool _googleLoading = false;
  String? _error;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = AuthService.authStream.listen((state) {
      final session = state.session;
      if (session != null && mounted) {
        final rawRole = AuthService.currentRole;
        final UserRole role = UserRole.values.firstWhere(
          (e) => e.name == rawRole,
          orElse: () => UserRole.peserta,
        );
        Navigator.pushReplacementNamed(context, AppRoutes.homeForRole(role));
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _registerWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });

    try {
      // Pemicu login Google nyata (OAuth) via Supabase
      await AuthService.signInWithGoogle(isTestingMock: false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception:', '').trim();
          _googleLoading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _googleLoading = false;
        });
      }
    }
  }

void _register() async {
  // 1. Ambil nilai bersih (tanpa spasi gaib di ujung) sejak awal
  final String name = _nameCtrl.text.trim();
  final String email = _emailCtrl.text.trim().toLowerCase();
  final String password = _passCtrl.text.trim();
  final String confirmPassword = _confCtrl.text.trim();

  // 2. Jalankan validasi menggunakan variabel yang sudah bersih
  if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
    setState(() { 
      _error = 'Semua field wajib diisi.'; 
    });
    return;
  }
  
  if (password != confirmPassword) {
    setState(() { 
      _error = 'Password konfirmasi tidak cocok.'; 
    });
    return;
  }
  
  if (password.length < 6) {
    setState(() { 
      _error = 'Password minimal harus 6 karakter (tanpa spasi).'; 
    });
    return;
  }

  // 3. Jika lolos validasi lokal, ubah status ke loading dan panggil API
  setState(() { _loading = true; _error = null; });

  try {
    await AuthService.register(
      name: name,
      email: email,
      password: password, // Menggunakan variabel password yang sudah terjamin panjangnya >= 6
      role: 'peserta',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Registrasi berhasil! Silakan login.'),
          backgroundColor: BooyahTheme.green,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  } catch (e) {
    if (mounted) {
      // Extract dan format error message
      String errorMsg = e.toString();
      if (errorMsg.contains('PostgrestException')) {
              // Kita potong stringnya agar langsung menampilkan detail kolom yang eror
              errorMsg = 'DB Error: ${e.toString().replaceAll('PostgrestException(message: ', '').replaceAll(')', '')}';
              debugPrint('Detail Eror PostgreSQL: $e');
      } else if (errorMsg.contains('already registered')) {
        errorMsg = 'Email sudah terdaftar. Silakan login atau gunakan email lain.';
      } else if (errorMsg.contains('weak password')) {
        errorMsg = 'Password terlalu lemah. Gunakan kombinasi huruf & angka.';
      } else {
        errorMsg = errorMsg.replaceAll('Exception:', '').trim();
        if (errorMsg.isEmpty) errorMsg = 'Terjadi kesalahan tidak diketahui.';
      }
      
      setState(() { 
        _error = errorMsg;
        _loading = false; 
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DAFTAR AKUN')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
    child: Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: BooyahTheme.maroon.withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.asset(
          'assets/images/logo.jpeg',
          fit: BoxFit.cover,
        ),
      ),
    ),
  ),

  const SizedBox(height: 24),

              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [BooyahTheme.maroonD, BooyahTheme.bg],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(' BUAT AKUN', style: TextStyle(
                      fontFamily: 'Orbitron', fontSize: 16,
                      fontWeight: FontWeight.w700, letterSpacing: 2,
                    )),
                    SizedBox(height: 4),
                    Text('Daftarkan diri Anda untuk mulai mengikuti turnamen',
                      style: TextStyle(fontSize: 12, color: BooyahTheme.textMuted)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildField('NAMA LENGKAP', _nameCtrl,
                icon: Icons.person_outline, hint: 'Contoh: Yosep Bima'),
              const SizedBox(height: 12),
              _buildField('EMAIL', _emailCtrl,
                icon: Icons.email_outlined, hint: 'email@contoh.com',
                keyboard: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildField('PASSWORD', _passCtrl,
                icon: Icons.lock_outline, hint: 'Minimal 6 karakter',
                obscure: true),
              const SizedBox(height: 12),
              _buildField('KONFIRMASI PASSWORD', _confCtrl,
                icon: Icons.lock_outline, hint: 'Ulangi password',
                obscure: true),

              if (_error != null) ...[
                const SizedBox(height: 12),
                _errorBox(_error!),
              ],

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('DAFTAR SEKARANG'),
              ),

              const SizedBox(height: 20),

              // ================= GOOGLE BUTTON =================

              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white12)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'ATAU DAFTAR DENGAN',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: BooyahTheme.textMuted.withValues(alpha: 0.8),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.white12)),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    backgroundColor: Colors.white.withValues(alpha: 0.03),
                  ),
                  onPressed: _googleLoading ? null : _registerWithGoogle,
                  child: _googleLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                              height: 18,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.login_rounded, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'DAFTAR DENGAN GOOGLE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Sudah punya akun? MASUK',
                    style: TextStyle(color: BooyahTheme.maroonB, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {
    required IconData icon,
    String? hint,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: BooyahTheme.textPri),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: BooyahTheme.maroonB, size: 18),
      ),
    );
  }

  Widget _errorBox(String msg) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: BooyahTheme.red.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: BooyahTheme.red.withValues(alpha: 0.4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: BooyahTheme.red, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg,
          style: const TextStyle(color: BooyahTheme.red, fontSize: 12))),
      ],
    ),
  );
}
