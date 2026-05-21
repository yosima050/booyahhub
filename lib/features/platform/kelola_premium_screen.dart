// ──────────────────────────────────────────────────────────
// FILE: lib/features/platform/kelola_premium_screen.dart
// UC-19: Mengelola Layanan Premium
// ──────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../services/supabase_service.dart';

class KelolaPremiumScreen extends StatefulWidget {
  const KelolaPremiumScreen({super.key});

  @override
  State<KelolaPremiumScreen> createState() => _KelolaPremiumScreenState();
}

class _KelolaPremiumScreenState extends State<KelolaPremiumScreen> {
  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _active = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loading = true);
      final pending = await PlatformService.getPremiumRequests();
      // You would need to create a method to fetch active premium admins
      // For now using empty list as placeholder
      setState(() {
        _pending = pending;
        _active = [];
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading premium data: $e');
      setState(() => _loading = false);
    }
  }

  void _approve(Map<String, dynamic> req) async {
    try {
      await PlatformService.processPremium(req['id'] as int, true);
      setState(() => _pending.removeWhere((p) => p['id'] == req['id']));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${req['admin_name']} berhasil di-upgrade ke Premium!'),
          backgroundColor: BooyahTheme.green));
    } catch (e) {
      debugPrint('Error approving premium: $e');
    }
  }

  void _reject(Map<String, dynamic> req) async {
    try {
      await PlatformService.processPremium(req['id'] as int, false);
      setState(() => _pending.removeWhere((p) => p['id'] == req['id']));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('❌ Permintaan premium ditolak.'),
          backgroundColor: BooyahTheme.red));
    } catch (e) {
      debugPrint('Error rejecting premium: $e');
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(title: const Text('LAYANAN PREMIUM'),
      actions: [Chip(label: const Text('PLATFORM', style: TextStyle(fontSize: 9)),
        backgroundColor: BooyahTheme.maroonGlow.withValues(alpha: 0.15),
        labelStyle: const TextStyle(color: BooyahTheme.maroonGlow, fontWeight: FontWeight.w700),
      ), const SizedBox(width: 8)]),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFB22222)))
        : SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Stats header
        Row(children: [
          _statBox('ADMIN\nPREMIUM', _active.length.toString(), BooyahTheme.gold),
          const SizedBox(width: 6),
          _statBox('MENUNGGU', _pending.length.toString(), BooyahTheme.yellow),
          const SizedBox(width: 6),
          _statBox('KEDALUWARSA', '0', BooyahTheme.red),
          const SizedBox(width: 6),
          _statBox('PENDAPATAN', 'Rp420k', BooyahTheme.green),
        ]),
        const SizedBox(height: 14),

        // Fitur premium
        const SectionHeader(title: 'KEUNGGULAN PREMIUM'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BooyahTheme.card, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.25)),
          ),
          child: Column(children: [
            _featureRow('🏅', 'Scrim ditampilkan di halaman utama (featured)'),
            _featureRow('📊', 'Laporan analytics detail per scrim'),
            _featureRow('🔑', 'Distribusi Room ID otomatis tanpa batas'),
            _featureRow('📣', 'Kirim pengumuman massal tanpa batas'),
            _featureRow('⭐', 'Badge "Admin Terpercaya" di profil'),
          ]),
        ),
        const SizedBox(height: 14),

        // Pending approval
        const SectionHeader(title: 'MENUNGGU APPROVAL'),
        if (_pending.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Tidak ada permintaan pending', style: TextStyle(color: BooyahTheme.textMuted)),
          )
        else
          ..._pending.map((req) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BooyahTheme.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Text('⭐', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(req['admin_name'] as String? ?? 'Admin', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(req['email'] as String? ?? '', style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted)),
                  Text(req['package_type'] as String? ?? '1 bulan · Rp50.000', style: const TextStyle(fontSize: 10, color: BooyahTheme.gold, fontWeight: FontWeight.w700)),
                ])),
                Row(children: [
                  GestureDetector(onTap: () => _approve(req),
                    child: _btn('✓ OK', BooyahTheme.green)),
                  const SizedBox(width: 4),
                  GestureDetector(onTap: () => _reject(req),
                    child: _btn('✕', BooyahTheme.red)),
                ]),
              ]),
            );
          }),

        const SizedBox(height: 14),

        // Active premium
        const SectionHeader(title: 'AKTIF PREMIUM'),
        if (_active.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Belum ada admin premium aktif', style: TextStyle(color: BooyahTheme.textMuted)),
          )
        else
          ..._active.asMap().entries.map((e) {
            final a = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: BooyahTheme.card, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Text(['🥇','🥈','🥉'][e.key % 3], style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a['admin_name'] as String? ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(a['status'] as String? ?? 'Aktif', style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('30 hari lagi', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: BooyahTheme.green)),
                  const SizedBox(height: 4),
                  _btn('Perbarui', BooyahTheme.yellow),
                ]),
              ]),
            );
          }),
      ]),
    ),
  );

  Widget _statBox(String label, String val, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: BooyahTheme.card, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 7, color: BooyahTheme.textMuted), textAlign: TextAlign.center),
      ]),
    ),
  );

  Widget _featureRow(String ico, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Text(ico, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: BooyahTheme.textSec))),
    ]),
  );

  Widget _btn(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      border: Border.all(color: color.withValues(alpha: 0.4)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );
}
