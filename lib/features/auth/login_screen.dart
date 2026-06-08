import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../services/supabase_service.dart';
import '../../services/push_notification_service.dart';
import '../../shared/models/models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;
  bool _navigated = false; // Guard against double navigation
  String? _error;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // authStream hanya digunakan untuk Google OAuth (redirect flow)
    // Login email ditangani langsung di _login()
    _authSub = AuthService.authStream.listen((state) async {
      final session = state.session;
      if (session != null && mounted && !_navigated && _googleLoading) {
        _navigated = true;
        // Sync profile ke public.users
        await AuthService.syncOrCreateUserProfile();
        // Initialize push notifications
        await PushNotificationService.initialize();

        final rawRole = AuthService.currentRole;
        final UserRole role = UserRole.values.firstWhere(
          (e) => e.name == rawRole,
          orElse: () => UserRole.peserta,
        );
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.homeForRole(role),
            (route) => false,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _loginWithGoogle() async {
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
      await AuthService.login(email: email, password: password);

      if (mounted && !_navigated) {
        _navigated = true;
        // Batalkan authStream agar tidak ikut menavigasi lagi
        await _authSub?.cancel();
        _authSub = null;

        // Sync profile ke public.users (menangani pemulihan jika profil admin hilang akibat bug UUID)
        await AuthService.syncOrCreateUserProfile();
        // Initialize push notifications
        await PushNotificationService.initialize();

        if (!mounted) return;

        final String rawRole = AuthService.currentRole;
        final UserRole role = UserRole.values.firstWhere(
          (e) => e.name == rawRole,
          orElse: () => UserRole.peserta,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selamat datang kembali di BooyahHub!'),
            backgroundColor: BooyahTheme.green,
          ),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.homeForRole(role),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceAll('Exception:', '').trim();

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
                      'assets/images/logo.jpeg',
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
                style: const TextStyle(color: BooyahTheme.textPri),
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
                style: const TextStyle(color: BooyahTheme.textPri),
                decoration: InputDecoration(
                  labelText: 'PASSWORD',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: BooyahTheme.maroonB,
                    size: 18,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
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

              // ================= GOOGLE BUTTON =================
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white12)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'ATAU MASUK DENGAN',
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
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.03),
                  ),
                  onPressed: _googleLoading ? null : _loginWithGoogle,
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
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.login_rounded, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'MASUK DENGAN GOOGLE',
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

              // ================= REGISTER =================
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.register);
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
