import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../core/auth_service.dart';

class PlatformProfileScreen extends StatelessWidget {
  const PlatformProfileScreen({super.key});

  void _logout(BuildContext ctx) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: BooyahTheme.card,
      title: const Text('LOGOUT', style: TextStyle(fontFamily:'Orbitron',fontSize:14,fontWeight:FontWeight.w700)),
      content: const Text('Yakin ingin keluar dari dashboard platform?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('BATAL', style: TextStyle(color: BooyahTheme.textMuted))),
        ElevatedButton(
          onPressed: () {
            AuthService().logout();
            Navigator.pushNamedAndRemoveUntil(ctx, AppRoutes.login, (r) => false);
          },
          style: ElevatedButton.styleFrom(backgroundColor: BooyahTheme.red),
          child: const Text('KELUAR'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext ctx) {
    final auth = AuthService();
    return Scaffold(
      appBar: AppBar(title: const Text('PROFIL PLATFORM'),
        actions: [Chip(
          label: const Text('PLATFORM', style: TextStyle(fontSize: 9)),
          backgroundColor: BooyahTheme.maroonGlow.withValues(alpha: 0.15),
          labelStyle: const TextStyle(color: BooyahTheme.maroonGlow, fontWeight: FontWeight.w700),
        ), const SizedBox(width: 8)]),
      body: SingleChildScrollView(
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.fromLTRB(16,24,16,24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF3A0000).withValues(alpha: 0.8), BooyahTheme.bg],
                begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
            child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BooyahTheme.maroonGlow,
                  border: Border.all(color: BooyahTheme.maroonGlow.withValues(alpha: 0.6), width: 2.5),
                  boxShadow: [BoxShadow(color: BooyahTheme.maroonGlow.withValues(alpha: 0.2), blurRadius: 16)],
                ),
                child: const Center(child: Text('🏢', style: TextStyle(fontSize: 36))),
              ),
              const SizedBox(height: 10),
              Text(auth.name, style: const TextStyle(
                fontFamily:'Orbitron', fontSize:16, fontWeight:FontWeight.w900, letterSpacing:1)),
              Text(auth.email, style: const TextStyle(fontSize:12, color:BooyahTheme.textMuted)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal:12, vertical:4),
                decoration: BoxDecoration(
                  color: BooyahTheme.maroonGlow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: BooyahTheme.maroonGlow.withValues(alpha: 0.4)),
                ),
                child: const Text('SUPER ADMIN · PENGELOLA APLIKASI',
                  style: TextStyle(fontSize:9, color:BooyahTheme.maroonGlow, fontWeight:FontWeight.w700, letterSpacing:1)),
              ),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _menuGroup('MANAJEMEN', [
                (Icons.people, 'Manajemen Akun', AppRoutes.manajemenAkun),
                (Icons.star, 'Kelola Premium', AppRoutes.kelolaPremium),
                (Icons.verified, 'Verifikasi Klaim', AppRoutes.verifKlaim),
              ], ctx),
              const SizedBox(height: 10),
              _menuGroup('LAPORAN & KEUANGAN', [
                (Icons.account_balance_wallet, 'Dashboard Keuangan', AppRoutes.dashKeuangan),
                (Icons.analytics, 'Laporan Keseluruhan', AppRoutes.laporanPlat),
              ], ctx),
              const SizedBox(height: 10),
              _menuGroup('SISTEM', [
                (Icons.person_outline, 'Edit Profil Platform', null),
                (Icons.settings, 'Pengaturan Sistem', null),
                (Icons.security, 'Audit Log', null),
              ], ctx),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _logout(ctx),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BooyahTheme.red.withValues(alpha: 0.08),
                    border: Border.all(color: BooyahTheme.red.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.logout, color: BooyahTheme.red, size: 18),
                    SizedBox(width: 8),
                    Text('KELUAR', style: TextStyle(fontSize: 14, color: BooyahTheme.red, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _menuGroup(String title, List<(IconData, String, String?)> items, BuildContext ctx) =>
      Container(
        decoration: BoxDecoration(
          color: BooyahTheme.card, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14,10,14,4),
            child: Text(title, style: const TextStyle(fontSize:10, color:BooyahTheme.textMuted, letterSpacing:1.5, fontWeight:FontWeight.w700)),
          ),
          ...items.map((m) => InkWell(
            onTap: m.$3 != null ? () => Navigator.pushNamed(ctx, m.$3!) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal:14, vertical:12),
              child: Row(children: [
                Icon(m.$1, color: BooyahTheme.maroonGlow, size: 18),
                const SizedBox(width: 12),
                Text(m.$2, style: const TextStyle(fontSize:13, fontWeight:FontWeight.w600, color:BooyahTheme.textSec)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: BooyahTheme.textMuted, size: 16),
              ]),
            ),
          )),
        ]),
      );
}
