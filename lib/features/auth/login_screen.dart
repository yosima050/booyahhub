import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../core/auth_service.dart';
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

  // Dummy credentials – ganti dengan API call
  static const _accounts = {
    'peserta@test.com':  (UserRole.peserta,  'FIRE WOLVES',        1),
    'admin@test.com':    (UserRole.admin,     'ProScrim_ID',        2),
    'platform@test.com': (UserRole.platform,  'BooyahHub Platform', 3),
  };

  void _login() async {
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(seconds: 1));

    final key = _emailCtrl.text.trim().toLowerCase();
    final acc  = _accounts[key];

    if (acc == null || _passCtrl.text != '123456') {
      setState(() {
        _error   = 'Email atau password salah.';
        _loading = false;
      });
      return;
    }

    // Simpan session
    AuthService().login(
      role:   acc.$1,
      name:   acc.$2,
      email:  key,
      userId: acc.$3,
    );

    if (mounted) {
      // Navigasi sesuai role
      Navigator.pushReplacementNamed(
        context, AppRoutes.homeForRole(acc.$1));
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
              const SizedBox(height: 40),

              // Logo
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: BooyahTheme.maroon,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(
                          color: BooyahTheme.maroon.withOpacity(0.4),
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

              const SizedBox(height: 48),

              // Form
              const Text('LOGIN', style: TextStyle(
                fontFamily: 'Orbitron', fontSize: 14,
                fontWeight: FontWeight.w700, letterSpacing: 2,
                color: BooyahTheme.textMuted,
              )),
              const SizedBox(height: 16),

              // Email
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

              // Password
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

              // Error
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
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
                      Expanded(child: Text(_error!,
                        style: const TextStyle(color: BooyahTheme.red, fontSize: 12),
                      )),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Login button
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('MASUK'),
                ),
              ),

              const SizedBox(height: 16),

              // Register link
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

              // DEBUG: Quick login shortcuts
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BooyahTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔧 DEBUG – Quick Login',
                      style: TextStyle(fontSize: 11, color: BooyahTheme.textMuted, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    _debugLoginBtn('👤 Masuk sebagai Peserta', 'peserta@test.com'),
                    const SizedBox(height: 6),
                    _debugLoginBtn('⚙️ Masuk sebagai Admin', 'admin@test.com'),
                    const SizedBox(height: 6),
                    _debugLoginBtn('🏢 Masuk sebagai Platform', 'platform@test.com'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _debugLoginBtn(String label, String email) {
    return GestureDetector(
      onTap: () {
        _emailCtrl.text = email;
        _passCtrl.text  = '123456';
        _login();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: BooyahTheme.maroon.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: BooyahTheme.maroon.withOpacity(0.3)),
        ),
        child: Text(label,
          style: const TextStyle(fontSize: 12, color: BooyahTheme.textSec, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
