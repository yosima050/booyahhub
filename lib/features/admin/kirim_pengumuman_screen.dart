// ──────────────────────────────────────────────────────────
// FILE: lib/features/admin/kirim_pengumuman_screen.dart
// UC-17: Mengirim Pengumuman
// ──────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/widgets/booyah_widgets.dart';

class KirimPengumumanScreen extends StatefulWidget {
  const KirimPengumumanScreen({super.key});

  @override
  State<KirimPengumumanScreen> createState() => _KirimPengumumanScreenState();
}

class _KirimPengumumanScreenState extends State<KirimPengumumanScreen> {
  final _judulCtrl = TextEditingController();
  final _isiCtrl   = TextEditingController();
  String _selectedScrim = 'BOOYAH CUP SEASON 7 – 11 Mar (11 peserta)';
  String _kategori = '📣 Pengumuman Umum';
  int _targetIdx = 0;
  bool _loading = false;

  final _scrims = [
    'BOOYAH CUP SEASON 7 – 11 Mar (11 peserta)',
    'MIDNIGHT CLASH RANKED – 11 Mar (16 peserta)',
    'Semua Scrim Aktif',
  ];
  final _kategoriList = ['📣 Pengumuman Umum','⏰ Perubahan Jadwal','⚠️ Peringatan','🏆 Hasil Pertandingan','💰 Info Hadiah'];
  final _targets = [('Semua Peserta','27'),('Terverifikasi Saja','11'),('Menunggu Bayar','4')];

  void _send() async {
    // UC-17 Alur Alternatif: validasi field kosong
    if (_judulCtrl.text.isEmpty || _isiCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Judul dan isi pesan tidak boleh kosong!'),
          backgroundColor: BooyahTheme.red));
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Terkirim ke ${_targets[_targetIdx].$2} peserta!'),
          backgroundColor: BooyahTheme.green));
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(title: const Text('KIRIM PENGUMUMAN'),
      actions: [Chip(label: const Text('ADMIN', style: TextStyle(fontSize: 9)),
        backgroundColor: BooyahTheme.yellow.withValues(alpha: 0.15),
        labelStyle: const TextStyle(color: BooyahTheme.yellow, fontWeight: FontWeight.w700),
      ), const SizedBox(width: 8)]),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'TARGET PENERIMA'),

        // Scrim select
        const Text('PILIH SCRIM TARGET *', style: TextStyle(fontSize: 10, color: BooyahTheme.textMuted, letterSpacing: 0.8)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: _selectedScrim, dropdownColor: BooyahTheme.surface,
          style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 12, color: BooyahTheme.textPri),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          items: _scrims.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _selectedScrim = v!),
        ),
        const SizedBox(height: 10),

        // Target filter
        Row(children: _targets.asMap().entries.map((e) {
          final active = _targetIdx == e.key;
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _targetIdx = e.key),
            child: Container(
              margin: EdgeInsets.only(right: e.key < 2 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? BooyahTheme.maroon.withValues(alpha: 0.15) : BooyahTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: active ? BooyahTheme.maroonB : BooyahTheme.maroon.withValues(alpha: 0.2)),
              ),
              child: Column(children: [
                Text(e.value.$2, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                  color: active ? BooyahTheme.maroonB : BooyahTheme.textSec)),
                Text(e.value.$1, style: const TextStyle(fontSize: 9, color: BooyahTheme.textMuted)),
              ]),
            ),
          ));
        }).toList()),
        const SizedBox(height: 14),
        const SectionHeader(title: 'ISI PESAN'),

        // Kategori
        const Text('KATEGORI *', style: TextStyle(fontSize: 10, color: BooyahTheme.textMuted, letterSpacing: 0.8)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: _kategori, dropdownColor: BooyahTheme.surface,
          style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 12, color: BooyahTheme.textPri),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          items: _kategoriList.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
          onChanged: (v) => setState(() => _kategori = v!),
        ),
        const SizedBox(height: 10),

        // Judul
        const Text('JUDUL *', style: TextStyle(fontSize: 10, color: BooyahTheme.textMuted, letterSpacing: 0.8)),
        const SizedBox(height: 5),
        TextField(controller: _judulCtrl,
          style: const TextStyle(color: BooyahTheme.textPri),
          decoration: const InputDecoration(hintText: 'cth: Perubahan Jadwal Scrim')),
        const SizedBox(height: 10),

        // Isi pesan
        const Text('ISI PESAN *', style: TextStyle(fontSize: 10, color: BooyahTheme.textMuted, letterSpacing: 0.8)),
        const SizedBox(height: 5),
        TextField(controller: _isiCtrl, maxLines: 4,
          style: const TextStyle(color: BooyahTheme.textPri),
          decoration: const InputDecoration(hintText: 'Tulis isi pengumuman di sini...')),
        const SizedBox(height: 14),

        // Preview
        const SectionHeader(title: 'PREVIEW NOTIFIKASI'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BooyahTheme.maroon.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(_kategori.split(' ').first, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_judulCtrl.text.isEmpty ? 'Judul pengumuman...' : _judulCtrl.text,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const Text('ProScrim_ID · Baru saja',
                  style: TextStyle(fontSize: 9, color: BooyahTheme.textMuted)),
              ])),
            ]),
            const SizedBox(height: 8),
            Text(_isiCtrl.text.isEmpty ? 'Isi pesan akan muncul di sini...' : _isiCtrl.text,
              style: const TextStyle(fontSize: 11, color: BooyahTheme.textSec, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 16),
        BooyahButton(label: '📣 KIRIM SEKARANG', onTap: _send, isLoading: _loading),
        const SizedBox(height: 20),
      ]),
    ),
  );
}
