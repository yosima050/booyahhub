import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../services/supabase_service.dart';

class KirimPengumumanScreen extends StatefulWidget {
  const KirimPengumumanScreen({super.key});

  @override
  State<KirimPengumumanScreen> createState() => _KirimPengumumanScreenState();
}

class _KirimPengumumanScreenState extends State<KirimPengumumanScreen> {
  final _judulCtrl = TextEditingController();
  final _isiCtrl = TextEditingController();
  String _kategori = 'Pengumuman Umum';
  int _targetIdx = 0;
  bool _loading = false;
  bool _screenLoading = true;
  late int scrimId;
  Map<String, dynamic>? _scrimData;

  int _allCount = 0;
  int _verifiedCount = 0;

  final _kategoriList = [
    'Pengumuman Umum',
    'Perubahan Jadwal',
    'Peringatan',
    'Hasil Pertandingan',
    'Info Hadiah',
  ];

  List<Map<String, dynamic>> get _targets => [
    {
      'label': 'Semua Peserta',
      'count': '$_allCount',
      'db_target': 'all',
    },
    {
      'label': 'Terverifikasi Saja',
      'count': '$_verifiedCount',
      'db_target': 'verified',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrimId = ModalRoute.of(context)!.settings.arguments as int? ?? 1;
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _screenLoading = true);
    try {
      final scrim = await ScrimService.getById(scrimId.toString());
      _scrimData = scrim;

      final regs = await RegistrationService.getByScrim(scrimId);
      setState(() {
        _allCount = regs.length;
        _verifiedCount = regs.where((r) => r['status'] == 'verified').length;
      });
    } catch (e) {
      debugPrint('Error loading scrim data: $e');
    } finally {
      setState(() => _screenLoading = false);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Perubahan Jadwal':
        return Icons.access_time_rounded;
      case 'Peringatan':
        return Icons.warning_amber_rounded;
      case 'Hasil Pertandingan':
        return Icons.emoji_events_outlined;
      case 'Info Hadiah':
        return Icons.monetization_on_outlined;
      default:
        return Icons.campaign_outlined;
    }
  }

  void _send() async {
    if (_judulCtrl.text.isEmpty || _isiCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Judul dan isi pesan tidak boleh kosong!'),
            ],
          ),
          backgroundColor: BooyahTheme.red,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final targetStr = _targets[_targetIdx]['db_target'] as String;
      final sentCount = await NotificationService.sendAnnouncement(
        title: _judulCtrl.text,
        message: _isiCtrl.text,
        scrimId: scrimId,
        target: targetStr,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text('Terkirim ke $sentCount peserta!'),
              ],
            ),
            backgroundColor: BooyahTheme.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error sending announcement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pengumuman: $e'),
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
      title: const Text('KIRIM PENGUMUMAN'),
      actions: [
        const SizedBox(width: 8),
      ],
    ),
    body: _screenLoading
        ? const Center(child: CircularProgressIndicator(color: BooyahTheme.maroon))
        : SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'TARGET PENERIMA'),

          // Scrim select
          const Text(
            'SCRIM TARGET *',
            style: TextStyle(
              fontSize: 10,
              color: BooyahTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: BooyahTheme.surface,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: BooyahTheme.maroon.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.sports_esports, size: 16, color: BooyahTheme.yellow),
                const SizedBox(width: 8),
                Text(
                  _scrimData?['title'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: BooyahTheme.textPri,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: _targets.asMap().entries.map((e) {
              final active = _targetIdx == e.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _targetIdx = e.key),
                  child: Container(
                    margin: EdgeInsets.only(right: e.key < 1 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active
                          ? BooyahTheme.maroon.withValues(alpha: 0.15)
                          : BooyahTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active
                            ? BooyahTheme.maroonB
                            : BooyahTheme.maroon.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          e.value['count']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: active
                                ? BooyahTheme.maroonB
                                : BooyahTheme.textSec,
                          ),
                        ),
                        Text(
                          e.value['label']!,
                          style: const TextStyle(
                            fontSize: 9,
                            color: BooyahTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const SectionHeader(title: 'ISI PESAN'),

          // Kategori
          const Text(
            'KATEGORI *',
            style: TextStyle(
              fontSize: 10,
              color: BooyahTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            initialValue: _kategori,
            dropdownColor: BooyahTheme.surface,
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 12,
              color: BooyahTheme.textPri,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: _kategoriList
                .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                .toList(),
            onChanged: (v) => setState(() => _kategori = v!),
          ),
          const SizedBox(height: 10),

          // Judul
          const Text(
            'JUDUL *',
            style: TextStyle(
              fontSize: 10,
              color: BooyahTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: _judulCtrl,
            style: const TextStyle(color: BooyahTheme.textPri),
            decoration: const InputDecoration(
              hintText: 'cth: Perubahan Jadwal Scrim',
            ),
          ),
          const SizedBox(height: 10),

          // Isi pesan
          const Text(
            'ISI PESAN *',
            style: TextStyle(
              fontSize: 10,
              color: BooyahTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: _isiCtrl,
            maxLines: 4,
            style: const TextStyle(color: BooyahTheme.textPri),
            decoration: const InputDecoration(
              hintText: 'Tulis isi pengumuman di sini...',
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
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(_kategori),
                      size: 24,
                      color: BooyahTheme.yellow,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _judulCtrl.text.isEmpty
                                ? 'Judul pengumuman...'
                                : _judulCtrl.text,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'ProScrim_ID · Baru saja',
                            style: TextStyle(
                              fontSize: 9,
                              color: BooyahTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isiCtrl.text.isEmpty
                      ? 'Isi pesan akan muncul di sini...'
                      : _isiCtrl.text,
                  style: const TextStyle(
                    fontSize: 11,
                    color: BooyahTheme.textSec,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BooyahButton(
            label: 'KIRIM SEKARANG',
            onTap: _send,
            isLoading: _loading,
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}
