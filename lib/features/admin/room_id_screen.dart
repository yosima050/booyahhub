import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../services/supabase_service.dart';
import '../../shared/models/enums/db_enums.dart';

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
  bool _loading = false;
  bool _saving = false;
  bool _screenLoading = true;
  Map<String, dynamic>? _scrim;
  late int scrimId;
  ScrimStatus _selectedStatus = ScrimStatus.ongoing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrimId = ModalRoute.of(context)!.settings.arguments as int? ?? 1;
      _loadScrim();
    });
  }

  Future<void> _loadScrim() async {
    setState(() => _screenLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('scrims')
          .select()
          .eq('id', scrimId)
          .isFilter('deleted_at', null)
          .single();

      setState(() {
        _scrim = res;
        _roomCtrl.text = _scrim?['room_id'] as String? ?? '';
        _passCtrl.text = _scrim?['room_password'] as String? ?? '';
        _selectedStatus = ScrimStatus.fromString(_scrim?['status']);
      });
    } catch (e) {
      debugPrint('Error loading scrim: $e');
    } finally {
      setState(() => _screenLoading = false);
    }
  }

  IconData _getStatusIcon(ScrimStatus status) {
    switch (status) {
      case ScrimStatus.draft:
        return Icons.edit_note;
      case ScrimStatus.open:
        return Icons.lock_open;
      case ScrimStatus.closed:
        return Icons.lock;
      case ScrimStatus.ongoing:
        return Icons.flash_on;
      case ScrimStatus.finished:
        return Icons.check_circle;
      case ScrimStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(ScrimStatus status) {
    switch (status) {
      case ScrimStatus.draft:
        return BooyahTheme.textMuted;
      case ScrimStatus.open:
        return BooyahTheme.green;
      case ScrimStatus.closed:
        return BooyahTheme.red;
      case ScrimStatus.ongoing:
        return BooyahTheme.yellow;
      case ScrimStatus.finished:
        return BooyahTheme.gold;
      case ScrimStatus.cancelled:
        return BooyahTheme.red;
    }
  }

  void _saveChanges() async {
    if (_scrim == null) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client
          .from('scrims')
          .update({
            'status': _selectedStatus.dbValue,
            'room_id': _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
            'room_password': _passCtrl.text.trim().isEmpty ? null : _passCtrl.text.trim(),
          })
          .eq('id', scrimId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Status scrim berhasil diubah menjadi ${_selectedStatus.displayText}!'),
              ],
            ),
            backgroundColor: BooyahTheme.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving scrim changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan perubahan status: $e'),
            backgroundColor: BooyahTheme.red,
          ),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  void _send() async {
    if (_scrim == null) return;
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
      // 1. Kirim Room ID & Password via RPC (mengupdate room info dan ubah status registrasi ke waiting_room_id)
      await ScrimService.sendRoomId(
        scrimId: scrimId,
        roomId: _roomCtrl.text,
        password: _passCtrl.text,
        extraMessage: _msgCtrl.text,
      );

      // 2. Mengubah status Scrim sesuai pilihan dropdown admin
      await Supabase.instance.client
          .from('scrims')
          .update({'status': _selectedStatus.dbValue})
          .eq('id', scrimId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Room ID terkirim & status scrim diubah menjadi ${_selectedStatus.displayText}!'),
              ],
            ),
            backgroundColor: BooyahTheme.green,
          ),
        );
        Navigator.pop(context);
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
        : _scrim == null
            ? const Center(child: Text('Sesi scrim tidak ditemukan.', style: TextStyle(color: BooyahTheme.textMuted)))
            : SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'SESI SCRIM TERPILIH'),
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A0000), Color(0xFF1E0000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: BooyahTheme.maroon.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sports_esports,
                    color: BooyahTheme.yellow,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _scrim?['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_scrim?['scheduled_at'] ?? ''} · ${_scrim?['slot_filled'] ?? 0}/${_scrim?['slot_total'] ?? 20} terverifikasi',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

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
                Expanded(
                  child: Text(
                    '${_scrim?['slot_filled'] ?? 0} tim terverifikasi · siap menerima Room ID',
                    style: const TextStyle(
                      fontSize: 11,
                      color: BooyahTheme.green,
                      fontWeight: FontWeight.w600,
                    ),
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
          const SizedBox(height: 12),
          const Text(
            'STATUS SCRIM *',
            style: TextStyle(
              fontSize: 10,
              color: BooyahTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<ScrimStatus>(
            key: ValueKey(_selectedStatus),
            initialValue: _selectedStatus,
            dropdownColor: BooyahTheme.surface,
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 13,
              color: BooyahTheme.textPri,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: ScrimStatus.values
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(s), color: _getStatusColor(s), size: 16),
                        const SizedBox(width: 8),
                        Text(s.displayText),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedStatus = v!),
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
                AnimatedBuilder(
                  animation: Listenable.merge([_roomCtrl, _passCtrl]),
                  builder: (context, _) {
                    return RichText(
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
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BooyahButton(
            label: 'SIMPAN DATA & UBAH STATUS',
            onTap: _saveChanges,
            isLoading: _saving,
            outlined: true,
            color: Colors.white70,
          ),
          const SizedBox(height: 10),
          BooyahButton(
            label: 'SIARKAN ROOM ID KE PESERTA',
            onTap: _send,
            isLoading: _loading,
            color: BooyahTheme.green,
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}
