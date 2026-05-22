// ──────────────────────────────────────────────────────────
// FILE: lib/features/admin/room_id_screen.dart
// UC-16: Mengelola Room ID
// ──────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../shared/widgets/booyah_widgets.dart';

class RoomIdScreen extends StatefulWidget {
  const RoomIdScreen({super.key});

  @override
  State<RoomIdScreen> createState() => _RoomIdScreenState();
}

class _RoomIdScreenState extends State<RoomIdScreen> {
  final _roomCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _msgCtrl = TextEditingController(
    text: 'Harap masuk room tepat waktu. GL HF semua!',
  );
  int _selectedScrim = 0;
  bool _loading = false;

  final _scrims = [
    {
      'name': 'BOOYAH CUP SEASON 7',
      'sched': '11 Mar · 19:00 WIB',
      'count': '11/20 terverifikasi',
    },
    {
      'name': 'MIDNIGHT CLASH RANKED',
      'sched': '11 Mar · 21:00 WIB',
      'count': '16/16 terverifikasi',
    },
  ];

  void _send() async {
    // UC-16: Validasi form & cek peserta
    if (_roomCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Data tidak boleh kosong!'),
          backgroundColor: BooyahTheme.red,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Room ID terkirim ke semua peserta terverifikasi!'),
          backgroundColor: BooyahTheme.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
      title: const Text('INPUT ROOM ID'),
      actions: [
        Chip(
          label: const Text('ADMIN', style: TextStyle(fontSize: 9)),
          backgroundColor: BooyahTheme.yellow.withValues(alpha: 0.15),
          labelStyle: const TextStyle(
            color: BooyahTheme.yellow,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'PILIH SESI SCRIM'),
          ..._scrims.asMap().entries.map(
            (e) => GestureDetector(
              onTap: () => setState(() => _selectedScrim = e.key),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedScrim == e.key
                      ? BooyahTheme.maroon.withValues(alpha: 0.1)
                      : BooyahTheme.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedScrim == e.key
                        ? BooyahTheme.maroonB
                        : BooyahTheme.maroon.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🎮', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.value['name']!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${e.value['sched']} · ${e.value['count']}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: BooyahTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedScrim == e.key)
                      const Icon(
                        Icons.check_circle,
                        color: BooyahTheme.maroonB,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          const SectionHeader(title: 'DATA ROOM'),

          // Peserta info
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: BooyahTheme.green.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: BooyahTheme.green.withValues(alpha: 0.25),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: BooyahTheme.green,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  '11 tim terverifikasi · siap menerima Room ID',
                  style: TextStyle(
                    fontSize: 11,
                    color: BooyahTheme.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ROOM ID *',
                      style: TextStyle(
                        fontSize: 10,
                        color: BooyahTheme.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _roomCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: BooyahTheme.textPri,
                        letterSpacing: 3,
                      ),
                      decoration: const InputDecoration(hintText: '0000000'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PASSWORD *',
                      style: TextStyle(
                        fontSize: 10,
                        color: BooyahTheme.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _passCtrl,
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: BooyahTheme.textPri,
                        letterSpacing: 3,
                      ),
                      decoration: const InputDecoration(hintText: 'pass'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'PESAN TAMBAHAN',
            style: TextStyle(
              fontSize: 10,
              color: BooyahTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: _msgCtrl,
            maxLines: 2,
            style: const TextStyle(color: BooyahTheme.textPri, fontSize: 12),
          ),

          const SizedBox(height: 14),
          const SectionHeader(title: 'PREVIEW NOTIFIKASI'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BooyahTheme.maroon.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: BooyahTheme.maroon.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('', style: TextStyle(fontSize: 20)),
                const SizedBox(height: 6),
                const Text(
                  'Room ID Tersedia',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 11,
                      color: BooyahTheme.textSec,
                    ),
                    children: [
                      const TextSpan(text: 'Room ID: '),
                      TextSpan(
                        text: _roomCtrl.text.isEmpty
                            ? '??????'
                            : _roomCtrl.text,
                        style: const TextStyle(
                          color: BooyahTheme.gold,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: ' · Password: '),
                      TextSpan(
                        text: _passCtrl.text.isEmpty
                            ? '??????'
                            : _passCtrl.text,
                        style: const TextStyle(
                          color: BooyahTheme.gold,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BooyahButton(
            label: 'KIRIM ROOM ID SEKARANG',
            onTap: _send,
            isLoading: _loading,
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}
