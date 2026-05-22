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

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  void _login() async {
    final String email = _emailCtrl.text.trim().toLowerCase();
    final String password = _passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Email dan password wajib diisi.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.login(
        email: email,
        password: password,
      );

      if (mounted) {
        final String rawRole = AuthService.currentRole;

        final UserRole role = UserRole.values.firstWhere(
          (e) => e.name == rawRole,
          orElse: () => UserRole.peserta,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ Selamat datang kembali di BooyahHub!'),
            backgroundColor: BooyahTheme.green,
          ),
        );

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.homeForRole(role),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString()
            .replaceAll('Exception:', '')
            .trim();

        if (errorMsg.contains('Invalid login credentials')) {
          errorMsg = 'Email atau password salah.';
        } else if (errorMsg.contains('Email not confirmed')) {
          errorMsg = 'Email belum dikonfirmasi.';
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

              const SizedBox(height: 50),

              // ================= LOGO =================

              Center(
                child: Container(
                  width: 180,
                  height: 180,
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
                      'assets/images/logo.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              const Text(
                'MASUK KE AKUN',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: BooyahTheme.textMuted,
                ),
              ),

              const SizedBox(height: 16),

              // ================= EMAIL =================

              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  color: BooyahTheme.textPri,
                ),
                decoration: const InputDecoration(
                  labelText: 'EMAIL',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: BooyahTheme.maroonB,
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ================= PASSWORD =================

              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(
                  color: BooyahTheme.textPri,
                ),
                decoration: InputDecoration(
                  labelText: 'PASSWORD',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: BooyahTheme.maroonB,
                    size: 18,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: BooyahTheme.textMuted,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscure = !_obscure;
                      });
                    },
                  ),
                ),
              ),

              // ================= ERROR =================

              if (_error != null) ...[
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: BooyahTheme.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: BooyahTheme.red.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: BooyahTheme.red,
                        size: 16,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: BooyahTheme.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ================= BUTTON =================

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('MASUK SEKARANG'),
                ),
              ),

              const SizedBox(height: 20),

              // ================= REGISTER =================

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.register,
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: 'Belum punya akun? ',
                      style: TextStyle(
                        color: BooyahTheme.textMuted,
                        fontSize: 13,
                      ),
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