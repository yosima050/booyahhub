import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../services/supabase_service.dart';
import '../../shared/models/models.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoadingGoogle = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Listen to Supabase Auth State Changes for Google OAuth Redirect
    _authSub = AuthService.authStream.listen((state) async {
      final session = state.session;
      if (session != null && mounted) {
        // Sync profile ke public.users
        await AuthService.syncOrCreateUserProfile();

        final rawRole = AuthService.currentRole;
        final UserRole role = UserRole.values.firstWhere(
          (e) => e.name == rawRole,
          orElse: () => UserRole.peserta,
        );
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.homeForRole(role));
        }
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // Google Login Action
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoadingGoogle = true;
    });

    try {
      // Pemicu login Google nyata (OAuth) via Supabase
      await AuthService.signInWithGoogle(isTestingMock: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal masuk Google: ${e.toString().replaceAll('Exception:', '')}',
            ),
            backgroundColor: BooyahTheme.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGoogle = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // 1. Sleek Gradient Base Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF060606),
                  Color(0xFF130808),
                  Color(0xFF0A0A0A),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. Main Center Splash Graphic & Branding
          Positioned(
            top: size.height * 0.15,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 3D Liquid Splash dari generate_image
                Opacity(
                  opacity: 0.85,
                  child: Image.asset(
                    'assets/images/welcome_splash.png',
                    fit: BoxFit.contain,
                  ),
                ),
                // Glowing BooyahHub branding overlay
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: BooyahTheme.maroon.withValues(alpha: 0.5),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/logo.jpeg',
                          width: 100,
                          height: 100,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'BOOYAH HUB',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(color: BooyahTheme.maroonGlow, blurRadius: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ultimate Gaming Scrim Arena',
                      style: TextStyle(
                        color: BooyahTheme.textMuted,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Simplified Actions Bottom Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: BoxDecoration(
                color: const Color(0xFF141414).withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: BooyahTheme.maroon.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Tombol Login Merah (Di Atas)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BooyahTheme.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                        shadowColor: BooyahTheme.red.withValues(alpha: 0.4),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.login);
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'MASUK KE AKUN',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Tombol Masuk dengan Google Putih (Di Bawah)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _isLoadingGoogle ? null : _handleGoogleSignIn,
                      child: _isLoadingGoogle
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                  height: 20,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.login_rounded, size: 20, color: Colors.black),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'MASUK DENGAN GOOGLE',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Register text link below
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.register);
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: 'Belum punya akun? ',
                        style: TextStyle(
                          color: BooyahTheme.textMuted,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: 'DAFTAR AKUN BARU',
                            style: TextStyle(
                              color: BooyahTheme.gold,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
