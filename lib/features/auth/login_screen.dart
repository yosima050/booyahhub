import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../services/supabase_service.dart';
import '../../shared/models/models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;
  bool _loading    = false;
  String? _error;

  void _login() async {
    final String email = _emailCtrl.text.trim().toLowerCase();
    final String password = _passCtrl.text.trim();

    // 1. Validasi Input Sederhana
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Email dan password wajib diisi.';
      });
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      // 2. Memanggil Autentikasi Asli Supabase
      await AuthService.login(
        email: email,
        password: password,
      );

if (mounted) {
        // 1. Ambil string role dari metadata Supabase ('peserta', 'admin', atau 'platform')
        final String rawRole = AuthService.currentRole;
        
        // 2. Lakukan konversi dari String ke Enum UserRole yang dimengerti oleh AppRoutes
        final UserRole role = UserRole.values.firstWhere(
          (e) => e.name == rawRole,
          orElse: () => UserRole.peserta, // Fallback aman jika terjadi anomali data
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ Selamat datang kembali di BooyahHub!'),
            backgroundColor: BooyahTheme.green,
          ),
        );

        // 3. Sekarang parameter 'role' sudah bertipe UserRole dan dijamin aman!
        Navigator.pushReplacementNamed(
          context, 
          AppRoutes.homeForRole(role),
        );
      }
    } catch (e) {
      if (mounted) {
        // Format penanganan pesan kesalahan login agar rapi
        String errorMsg = e.toString().replaceAll('Exception:', '').trim();
        if (errorMsg.contains('Invalid login credentials')) {
          errorMsg = 'Email atau password yang Anda masukkan salah.';
        } else if (errorMsg.contains('Email not confirmed')) {
          errorMsg = 'Email Anda belum dikonfirmasi. Silakan cek kotak masuk.';
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Logo Komunitas BooyahHub
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: BooyahTheme.maroon,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(
                          color: BooyahTheme.maroon.withValues(alpha: 0.4),
                          blurRadius: 20, spreadRadius: 2,
                        )],
                      ),
                      child: const Center(
                        child: Text('B',
                          style: TextStyle(
                            fontFamily: 'Orbitron', fontSize: 32,
                            fontWeight: FontWeight.w900, color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('BOOYAHHUB',
                      style: TextStyle(
                        fontFamily: 'Orbitron', fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: BooyahTheme.maroonB,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Platform Scrim Free Fire Indonesia',
                      style: TextStyle(fontSize: 12, color: BooyahTheme.textMuted),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 56),

              const Text('MASUK KE AKUN', style: TextStyle(
                fontFamily: 'Orbitron', fontSize: 13,
                fontWeight: FontWeight.w700, letterSpacing: 2,
                color: BooyahTheme.textMuted,
              )),
              const SizedBox(height: 16),

              // Input Email
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: BooyahTheme.textPri),
                decoration: const InputDecoration(
                  labelText: 'EMAIL',
                  prefixIcon: Icon(Icons.email_outlined, color: BooyahTheme.maroonB, size: 18),
                ),
              ),
              const SizedBox(height: 12),

              // Input Password
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: BooyahTheme.textPri),
                decoration: InputDecoration(
                  labelText: 'PASSWORD',
                  prefixIcon: const Icon(Icons.lock_outline, color: BooyahTheme.maroonB, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: BooyahTheme.textMuted, size: 18,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              // Tampilan Alert Kotak Eror
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
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
                      Expanded(child: Text(_error!,
                        style: const TextStyle(color: BooyahTheme.red, fontSize: 12),
                      )),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Tombol Eksekusi Login
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('MASUK SEKARANG'),
                ),
              ),

              const SizedBox(height: 20),

              // Tautan Pindah ke Register
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Belum punya akun? ',
                      style: TextStyle(color: BooyahTheme.textMuted, fontSize: 13),
                      children: [
                        TextSpan(
                          text: 'DAFTAR',
                          style: TextStyle(
                            color: BooyahTheme.maroonB,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
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
}