import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../services/supabase_service.dart';

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
  int _selectedScrimIdx = 0;
  bool _loading = false;
  bool _screenLoading = true;
  List<Map<String, dynamic>> _scrims = [];
  late int scrimId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrimId = ModalRoute.of(context)!.settings.arguments as int? ?? 1;
      _loadScrims();
    });
  }

  Future<void> _loadScrims() async {
    setState(() => _screenLoading = true);
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        // Resolve admin's BigInt ID from users table using their UUID
        final userProfile = await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('uuid', currentUser.id)
            .single();
        final int adminBigId = userProfile['id'];

        // Fetch scrims for this admin
        final res = await Supabase.instance.client
            .from('scrims')
            .select()
            .eq('admin_id', adminBigId)
            .isFilter('deleted_at', null)
            .order('scheduled_at', ascending: true);

        setState(() {
          _scrims = List<Map<String, dynamic>>.from(res);
          
          // Pre-select the scrim that matches the passed argument
          _selectedScrimIdx = _scrims.indexWhere((s) => s['id'] == scrimId);
          if (_selectedScrimIdx == -1) _selectedScrimIdx = 0;

          if (_scrims.isNotEmpty) {
            _roomCtrl.text = _scrims[_selectedScrimIdx]['room_id'] as String? ?? '';
            _passCtrl.text = _scrims[_selectedScrimIdx]['room_password'] as String? ?? '';
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading active scrims: $e');
    } finally {
      setState(() => _screenLoading = false);
    }
  }

  void _selectScrim(int index) {
    setState(() {
      _selectedScrimIdx = index;
      final selectedScrim = _scrims[index];
      _roomCtrl.text = selectedScrim['room_id'] as String? ?? '';
      _passCtrl.text = selectedScrim['room_password'] as String? ?? '';
    });
  }

  void _send() async {
    if (_scrims.isEmpty) return;
    if (_roomCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Data tidak boleh kosong!'),
            ],
          ),
          backgroundColor: BooyahTheme.red,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final targetScrimId = _scrims[_selectedScrimIdx]['id'] as int;
      await ScrimService.sendRoomId(
        scrimId: targetScrimId,
        roomId: _roomCtrl.text,
        password: _passCtrl.text,
        extraMessage: _msgCtrl.text,
      );
      if (mounted) {
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
    } catch (e) {
      debugPrint('Error sending room ID: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim Room ID: $e'),
            backgroundColor: BooyahTheme.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
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
    body: _screenLoading
        ? const Center(child: CircularProgressIndicator(color: BooyahTheme.maroon))
        : _scrims.isEmpty
            ? const Center(child: Text('Belum ada sesi scrim aktif.', style: TextStyle(color: BooyahTheme.textMuted)))
            : SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'PILIH SESI SCRIM'),
          ..._scrims.asMap().entries.map(
            (e) => GestureDetector(
              onTap: () => _selectScrim(e.key),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedScrimIdx == e.key
                      ? BooyahTheme.maroon.withValues(alpha: 0.1)
                      : BooyahTheme.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedScrimIdx == e.key
                        ? BooyahTheme.maroonB
                        : BooyahTheme.maroon.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sports_esports,
                      size: 18,
                      color: BooyahTheme.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.value['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${e.value['scheduled_at'] ?? ''} · ${e.value['slot_filled'] ?? 0}/${e.value['slot_total'] ?? 20} terverifikasi',
                            style: const TextStyle(
                              fontSize: 10,
                              color: BooyahTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedScrimIdx == e.key)
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
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: BooyahTheme.green,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_scrims[_selectedScrimIdx]['slot_filled'] ?? 0} tim terverifikasi · siap menerima Room ID',
                  style: const TextStyle(
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
