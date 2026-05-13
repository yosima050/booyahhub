import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';

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
  String? _error;

  void _register() async {
    setState(() { _loading = true; _error = null; });

    // Validasi dasar
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty || _confCtrl.text.isEmpty) {
      setState(() { _error = 'Semua field wajib diisi.'; _loading = false; });
      return;
    }
    if (_passCtrl.text != _confCtrl.text) {
      setState(() { _error = 'Password tidak cocok.'; _loading = false; });
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() { _error = 'Password minimal 6 karakter.'; _loading = false; });
      return;
    }

    await Future.delayed(const Duration(seconds: 1)); // simulate network
    // TODO: Ganti dengan API call ke backend

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Registrasi berhasil! Silakan login.'),
          backgroundColor: BooyahTheme.green,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
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
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [BooyahTheme.maroonD, BooyahTheme.bg],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BooyahTheme.maroon.withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔥 BUAT AKUN', style: TextStyle(
                      fontFamily: 'Orbitron', fontSize: 16,
                      fontWeight: FontWeight.w700, letterSpacing: 2,
                    )),
                    SizedBox(height: 4),
                    Text('Daftarkan dirimu sebagai Ketua Tim / Peserta',
                      style: TextStyle(fontSize: 12, color: BooyahTheme.textMuted)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildField('NAMA LENGKAP / NAMA TIM', _nameCtrl,
                icon: Icons.group, hint: 'Contoh: FIRE WOLVES'),
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
      color: BooyahTheme.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: BooyahTheme.red.withOpacity(0.4)),
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
