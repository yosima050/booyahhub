import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../shared/widgets/booyah_widgets.dart';

class BuatScrimScreen extends StatefulWidget {
  const BuatScrimScreen({super.key});

  @override
  State<BuatScrimScreen> createState() => _BuatScrimScreenState();
}

class _BuatScrimScreenState extends State<BuatScrimScreen> {
  final _namaCtrl = TextEditingController(text: '');
  final _deskCtrl = TextEditingController();
  final _kuotaCtrl = TextEditingController(text: '20');
  final _biayaCtrl = TextEditingController(text: '25000');
  final _aturCtrl = TextEditingController();
  String _mode = 'Battle Royale';
  String _server = 'Official Server';
  DateTime? _tanggal;
  TimeOfDay? _jamMulai;
  bool _loading = false;

  int get _biaya => int.tryParse(_biayaCtrl.text) ?? 0;
  int get _kuota => int.tryParse(_kuotaCtrl.text) ?? 0;
  int get _gross => _biaya * _kuota;
  int get _feePlat => (_gross * 0.05).round();
  int get _feeAdm => (_gross * 0.0375).round();
  int get _hadiah => (_gross * 0.85).round();

  void _saveScrim({required String status}) async {
    // Validasi UC-02 Langkah 6a
    if (_namaCtrl.text.isEmpty ||
        _kuotaCtrl.text.isEmpty ||
        _biayaCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Semua field wajib diisi!'),
            ],
          ),
          backgroundColor: BooyahTheme.red,
        ),
      );
      return;
    }
    if (_tanggal == null || _jamMulai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Tanggal dan jam mulai harus dipilih!'),
            ],
          ),
          backgroundColor: BooyahTheme.red,
        ),
      );
      return;
    }
    if (_tanggal!.isBefore(DateTime.now().add(const Duration(days: -1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Tanggal tidak valid (backdate)!'),
            ],
          ),
          backgroundColor: BooyahTheme.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Gabungkan DateTime dan TimeOfDay ke format ISO8601
      final scheduledDateTime = DateTime(
        _tanggal!.year,
        _tanggal!.month,
        _tanggal!.day,
        _jamMulai!.hour,
        _jamMulai!.minute,
      );

      // Hitung waktu tutup pendaftaran (1 jam sebelum jadwal mulai scrim)
      final registrationClosesAt = scheduledDateTime.subtract(
        const Duration(hours: 1),
      );

      // Ambil current user ID dari Supabase Auth
      final currentAuthUser = Supabase.instance.client.auth.currentUser;
      if (currentAuthUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Anda harus login terlebih dahulu'),
                ],
              ),
              backgroundColor: BooyahTheme.red,
            ),
          );
        }
        setState(() => _loading = false);
        return;
      }

      // Ambil bigint ID dari tabel users berdasarkan UUID auth
      final userProfile = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('uuid', currentAuthUser.id)
          .single();
      final int adminBigId = userProfile['id'];

      // Konversi mode ke format enum database ('battle_royale' atau 'clash_squad')
      final String dbMode = _mode == 'Clash Squad'
          ? 'clash_squad'
          : 'battle_royale';

      // INSERT data scrim baru ke tabel 'scrims'
      await Supabase.instance.client.from('scrims').insert({
        'title': _namaCtrl.text.trim(),
        'mode': dbMode,
        'server': _server,
        'description': _deskCtrl.text.trim(),
        'scheduled_at': scheduledDateTime.toIso8601String(),
        'registration_closes_at': registrationClosesAt.toIso8601String(),
        'slot_total': int.parse(_kuotaCtrl.text),
        'fee': int.parse(_biayaCtrl.text),
        'rules': _aturCtrl.text.trim(),
        'admin_id': adminBigId,
        'status': status,
      });

      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  status == 'open'
                      ? Icons.check_circle_outline
                      : Icons.archive_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  status == 'open'
                      ? 'Scrim berhasil dibuat dan dipublikasikan!'
                      : 'Scrim berhasil disimpan sebagai Draft!',
                ),
              ],
            ),
            backgroundColor: BooyahTheme.green,
          ),
        );
        Navigator.pop(context, true); // Return true untuk trigger refresh
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: BooyahTheme.red,
          ),
        );
      }
      debugPrint('Error saving scrim: $e');
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
      title: const Text('BUAT SCRIM BARU'),
      actions: [
        Chip(
          label: const Text(
            'ADMIN',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
          ),
          backgroundColor: BooyahTheme.yellow.withValues(alpha: 0.15),
          side: BorderSide(color: BooyahTheme.yellow.withValues(alpha: 0.4)),
          labelStyle: const TextStyle(color: BooyahTheme.yellow),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'INFO PERTANDINGAN'),
          _label('NAMA SCRIM', required: true),
          TextField(
            controller: _namaCtrl,
            style: const TextStyle(color: BooyahTheme.textPri),
            decoration: const InputDecoration(
              hintText: 'cth: BOOYAH CUP SEASON 8',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('MODE', required: true),
                    DropdownButtonFormField<String>(
                      initialValue: _mode,
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
                      items: ['Battle Royale', 'Clash Squad']
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _mode = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('SESI / SERVER', required: true),
                    DropdownButtonFormField<String>(
                      initialValue: _server,
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
                      items: ['Official Server', 'Advance Server']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _server = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _label('DESKRIPSI'),
          TextField(
            controller: _deskCtrl,
            maxLines: 3,
            style: const TextStyle(color: BooyahTheme.textPri),
            decoration: const InputDecoration(
              hintText: 'Jelaskan detail scrim...',
            ),
          ),
          const SizedBox(height: 16),

          const SectionHeader(title: 'JADWAL & KUOTA'),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('TANGGAL', required: true),
                    GestureDetector(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 1),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (d != null) setState(() => _tanggal = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: BooyahTheme.surface,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: BooyahTheme.maroon.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: BooyahTheme.maroonB,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _tanggal != null
                                  ? '${_tanggal!.day}/${_tanggal!.month}/${_tanggal!.year}'
                                  : 'Pilih tanggal',
                              style: TextStyle(
                                fontSize: 12,
                                color: _tanggal != null
                                    ? BooyahTheme.textPri
                                    : BooyahTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
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
                    _label('JAM MULAI', required: true),
                    GestureDetector(
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 19, minute: 0),
                        );
                        if (t != null) setState(() => _jamMulai = t);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: BooyahTheme.surface,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: BooyahTheme.maroon.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: BooyahTheme.maroonB,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _jamMulai != null
                                  ? _jamMulai!.format(context)
                                  : 'Pilih jam',
                              style: TextStyle(
                                fontSize: 12,
                                color: _jamMulai != null
                                    ? BooyahTheme.textPri
                                    : BooyahTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('KUOTA TIM', required: true),
                    TextField(
                      controller: _kuotaCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: BooyahTheme.textPri,
                        fontFamily: 'Orbitron',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(hintText: '20'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('BIAYA DAFTAR (Rp)', required: true),
                    TextField(
                      controller: _biayaCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: BooyahTheme.textPri),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(hintText: '25000'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Auto-calc
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BooyahTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: BooyahTheme.gold.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'KALKULASI OTOMATIS',
                  style: TextStyle(
                    fontSize: 10,
                    color: BooyahTheme.textMuted,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                _calcRow(
                  'Total Pendapatan',
                  'Rp${_fmt(_gross)}',
                  BooyahTheme.textSec,
                ),
                _calcRow(
                  'Fee Platform (5%)',
                  '-Rp${_fmt(_feePlat)}',
                  BooyahTheme.red,
                ),
                _calcRow(
                  'Fee Admin (3.75%)',
                  '+Rp${_fmt(_feeAdm)}',
                  BooyahTheme.yellow,
                ),
                const Divider(color: Colors.white12),
                _calcRow(
                  'Dana Hadiah (85%)',
                  'Rp${_fmt(_hadiah)}',
                  BooyahTheme.gold,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'PERATURAN TAMBAHAN'),
          TextField(
            controller: _aturCtrl,
            maxLines: 3,
            style: const TextStyle(color: BooyahTheme.textPri),
            decoration: const InputDecoration(hintText: 'Opsional...'),
          ),
          const SizedBox(height: 20),
          BooyahButton(
            label: 'SIMPAN & PUBLIKASIKAN',
            onTap: () => _saveScrim(status: 'open'),
            isLoading: _loading,
          ),
          const SizedBox(height: 8),
          BooyahButton(
            label: 'SIMPAN SEBAGAI DRAFT',
            outlined: true,
            onTap: _loading ? null : () => _saveScrim(status: 'draft'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );

  Widget _label(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 10,
          color: BooyahTheme.textMuted,
          letterSpacing: 0.8,
        ),
        children: required
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: BooyahTheme.maroonGlow),
                ),
              ]
            : [],
      ),
    ),
  );

  Widget _calcRow(String label, String val, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: BooyahTheme.textMuted),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(0)}k' : '$n';
}
