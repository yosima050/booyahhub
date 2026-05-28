// ──────────────────────────────────────────────────────────
// FILE: lib/features/admin/kelola_room_info_screen.dart
// UC-16 & UC-08: Kelola Room ID & Info Match (Gabungan)
// ──────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../shared/widgets/booyah_widgets.dart';

class KelolaRoomInfoScreen extends StatefulWidget {
  const KelolaRoomInfoScreen({super.key});

  @override
  State<KelolaRoomInfoScreen> createState() => _KelolaRoomInfoScreenState();
}

class _KelolaRoomInfoScreenState extends State<KelolaRoomInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Room ID
  final _roomCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _msgCtrl = TextEditingController(
    text: 'Harap masuk room tepat waktu. GL HF semua!',
  );
  bool _roomLoading = false;

  // Info Match
  final _matchInfoCtrl = TextEditingController();
  final _mapCtrl = TextEditingController(text: 'BERMUDA');
  String _matchStatus = 'Belum Dimulai';
  bool _matchLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _roomCtrl.dispose();
    _passCtrl.dispose();
    _msgCtrl.dispose();
    _matchInfoCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  void _sendRoomId() async {
    if (_roomCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Room ID dan Password tidak boleh kosong!'),
            ],
          ),
          backgroundColor: BooyahTheme.red,
        ),
      );
      return;
    }
    setState(() => _roomLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _roomLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Room ID terkirim ke semua peserta terverifikasi!'),
            ],
          ),
          backgroundColor: BooyahTheme.green,
        ),
      );
    }
  }

  void _updateMatchInfo() async {
    if (_matchInfoCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Info pertandingan tidak boleh kosong!'),
            ],
          ),
          backgroundColor: BooyahTheme.red,
        ),
      );
      return;
    }
    setState(() => _matchLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _matchLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Info pertandingan berhasil diupdate!'),
            ],
          ),
          backgroundColor: BooyahTheme.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
      title: const Text('KELOLA ROOM & INFO MATCH'),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: BooyahTheme.maroonB,
        labelColor: BooyahTheme.maroonB,
        unselectedLabelColor: BooyahTheme.textMuted,
        labelStyle: const TextStyle(
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        tabs: const [
          Tab(text: 'ROOM ID', icon: Icon(Icons.vpn_key_rounded)),
          Tab(text: 'INFO MATCH', icon: Icon(Icons.info_outline_rounded)),
        ],
      ),
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
    body: TabBarView(
      controller: _tabController,
      children: [
        // TAB 1: ROOM ID
        SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Scrim
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: BooyahTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: BooyahTheme.maroon.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: BooyahTheme.maroon.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.sports_esports,
                        color: BooyahTheme.yellow,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BOOYAH CUP SEASON 7',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            '11 Mar 2026 · 19:00 WIB',
                            style: TextStyle(
                              fontSize: 10,
                              color: BooyahTheme.textMuted,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: BooyahTheme.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '11/20 TIM TERVERIFIKASI',
                              style: TextStyle(
                                fontSize: 8,
                                color: BooyahTheme.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SectionHeader(title: 'ROOM CUSTOM'),

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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: BooyahTheme.textPri,
                            letterSpacing: 3,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0000000',
                            prefixIcon: Icon(Icons.meeting_room, size: 18),
                          ),
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
                          decoration: const InputDecoration(
                            hintText: 'pass',
                            prefixIcon: Icon(Icons.lock_outline, size: 18),
                          ),
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
                style: const TextStyle(
                  color: BooyahTheme.textPri,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 14),

              // Preview
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
                    const Row(
                      children: [
                        Icon(
                          Icons.vpn_key_outlined,
                          size: 20,
                          color: BooyahTheme.yellow,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Room ID Tersedia',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 4),
                    Text(
                      _msgCtrl.text.isEmpty
                          ? 'Harap masuk room tepat waktu.'
                          : _msgCtrl.text,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BooyahButton(
                label: 'KIRIM ROOM ID SEKARANG',
                onTap: _sendRoomId,
                isLoading: _roomLoading,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        // TAB 2: INFO MATCH
        SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Match
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BooyahTheme.maroon.withValues(alpha: 0.3),
                      BooyahTheme.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: BooyahTheme.maroon.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: BooyahTheme.maroon.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: BooyahTheme.yellow,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STATUS MATCH',
                            style: TextStyle(
                              fontSize: 9,
                              color: BooyahTheme.textMuted,
                              letterSpacing: 1,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _matchStatus == 'Live'
                                      ? BooyahTheme.red
                                      : _matchStatus == 'Selesai'
                                      ? BooyahTheme.green
                                      : BooyahTheme.yellow,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _matchStatus,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _matchStatus == 'Live'
                                      ? BooyahTheme.red
                                      : _matchStatus == 'Selesai'
                                      ? BooyahTheme.green
                                      : BooyahTheme.yellow,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status selector
                    DropdownButton<String>(
                      value: _matchStatus,
                      dropdownColor: BooyahTheme.surface,
                      underline: const SizedBox(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: BooyahTheme.textPri,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Belum Dimulai',
                          child: Text('Belum Dimulai'),
                        ),
                        DropdownMenuItem(value: 'Live', child: Text('Live')),
                        DropdownMenuItem(
                          value: 'Selesai',
                          child: Text('Selesai'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _matchStatus = v!),
                    ),
                  ],
                ),
              ),

              const SectionHeader(title: 'INFORMASI PERTANDINGAN'),

              const Text(
                'MAP',
                style: TextStyle(
                  fontSize: 10,
                  color: BooyahTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: _mapCtrl.text,
                dropdownColor: BooyahTheme.surface,
                style: const TextStyle(
                  color: BooyahTheme.textPri,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.map_outlined, size: 18),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'BERMUDA',
                    child: Text('🇧🇲 BERMUDA'),
                  ),
                  DropdownMenuItem(
                    value: 'PURGATORY',
                    child: Text('🔥 PURGATORY'),
                  ),
                  DropdownMenuItem(
                    value: 'KALAHARI',
                    child: Text('🏜️ KALAHARI'),
                  ),
                  DropdownMenuItem(value: 'NEXTERA', child: Text('🌌 NEXTERA')),
                ],
                onChanged: (v) => setState(() => _mapCtrl.text = v!),
              ),
              const SizedBox(height: 10),

              const Text(
                'INFO PERTANDINGAN',
                style: TextStyle(
                  fontSize: 10,
                  color: BooyahTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: _matchInfoCtrl,
                maxLines: 4,
                style: const TextStyle(color: BooyahTheme.textPri),
                decoration: const InputDecoration(
                  hintText:
                      'Contoh:\n• Match ke-1 dari 3\n• Cuaca: Clear\n• Mode: Battle Royale',
                  prefixIcon: Icon(Icons.info_outline, size: 18),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 16),

              // Preview Info Match
              const SectionHeader(title: 'PREVIEW INFO MATCH'),
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
                    Row(
                      children: [
                        const Icon(
                          Icons.map,
                          size: 16,
                          color: BooyahTheme.yellow,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'MAP: ${_mapCtrl.text}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _matchStatus == 'Live'
                                ? BooyahTheme.red.withValues(alpha: 0.15)
                                : _matchStatus == 'Selesai'
                                ? BooyahTheme.green.withValues(alpha: 0.15)
                                : BooyahTheme.yellow.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _matchStatus,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: _matchStatus == 'Live'
                                  ? BooyahTheme.red
                                  : _matchStatus == 'Selesai'
                                  ? BooyahTheme.green
                                  : BooyahTheme.yellow,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 6),
                    Text(
                      _matchInfoCtrl.text.isEmpty
                          ? 'Belum ada info pertandingan yang diinput.'
                          : _matchInfoCtrl.text,
                      style: const TextStyle(
                        fontSize: 11,
                        color: BooyahTheme.textSec,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: BooyahTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Last updated: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: BooyahTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              BooyahButton(
                label: 'UPDATE INFO MATCH',
                onTap: _updateMatchInfo,
                isLoading: _matchLoading,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    ),
  );
}
