import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../services/supabase_service.dart';

class DetailScrimScreen extends StatefulWidget {
  const DetailScrimScreen({super.key});

  @override
  State<DetailScrimScreen> createState() => DetailScrimScreenState();
}

class DetailScrimScreenState extends State<DetailScrimScreen> {
  ScrimModel? _scrim;
  bool _loading = true;
  String? _error;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadScrim();
    }
  }

  Future<void> _loadScrim() async {
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      String scrimId = '1';
      if (args is String) {
        scrimId = args;
      } else if (args is num) {
        scrimId = args.toString();
      } else if (args is ScrimModel) {
        scrimId = args.id;
      } else if (args != null) {
        if (args is Map && args['id'] != null) {
          scrimId = args['id'].toString();
        } else {
          scrimId = args.toString();
        }
      }
      final data = await ScrimService.getById(scrimId);
      
      setState(() {
        _scrim = ScrimModel(
          id: data['id'].toString(),
          title: data['title'] as String,
          adminName: (data['admin_profiles']?['display_name'] ?? 'Unknown') as String,
          date: _fmtDate(data['scheduled_at'] as String),
          time: _fmtTime(data['scheduled_at'] as String),
          mode: _formatMode(data['mode'] as String),
          slotFilled: data['slot_filled'] as int,
          slotTotal: data['slot_total'] as int,
          fee: data['fee'] as int,
          prize: data['prize_pool'] as int,
          isPremium: data['is_premium'] as bool? ?? false,
          description: data['description'] as String? ?? '',
        );
      });
    } catch (e) {
      debugPrint('Error loading scrim: $e');
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _formatMode(String text) {
  return text.split('_').map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

  String _fmtDate(String iso) {
    final d = DateTime.parse(iso).toLocal();
    const months = ['','Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agt','Sep','Okt','Nov','Des'];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  String _fmtTime(String iso) {
    final d = DateTime.parse(iso).toLocal();
    return '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')} WIB';
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFB22222)))
        : _error != null
            ? Center(child: Text('Error: $_error', style: const TextStyle(color: BooyahTheme.red)))
            : _scrim == null
                ? const Center(child: Text('Scrim tidak ditemukan', style: TextStyle(color: BooyahTheme.textMuted)))
                : SafeArea(
                    top: true, 
                    child: CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          expandedHeight: 180,
                          pinned: true,
                          backgroundColor: BooyahTheme.maroonD,
                          flexibleSpace: FlexibleSpaceBar(
                            background: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [BooyahTheme.maroonD, BooyahTheme.bg],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 50),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.sports_esports,
                                      size: 35,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _scrim!.title,
                                      style: const TextStyle(
                                        fontFamily: 'Orbitron',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    Text(
                                      '${_scrim!.adminName} • ${_scrim!.date} · ${_scrim!.time}',
                                      style: const TextStyle(fontSize: 11, color: BooyahTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              // Info grid
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 3.2,
                                  children: [
                                    _infoCell(
                                      const Icon(Icons.gps_fixed, size: 16, color: Colors.white),
                                      'MODE',
                                      _scrim!.mode,
                                    ),
                                    _infoCell(
                                      const Icon(Icons.groups, size: 16, color: Colors.white),
                                      'KUOTA',
                                      '${_scrim!.slotFilled}/${_scrim!.slotTotal} TIM',
                                    ),
                                    _infoCell(
                                      const Icon(Icons.payments, size: 16, color: Colors.white),
                                      'BIAYA',
                                      'Rp${_scrim!.fee ~/ 1000}k',
                                      valColor: BooyahTheme.gold,
                                    ),
                                    _infoCell(
                                      const Icon(Icons.emoji_events, size: 16, color: Colors.white),
                                      'HADIAH',
                                      'Rp${_scrim!.prize ~/ 1000}k',
                                      valColor: BooyahTheme.gold,
                                    ),
                                  ],
                                ),
                              ),

                              // Slot progress
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('PERKEMBANGAN SLOT', style: TextStyle(fontSize: 10, color: BooyahTheme.textMuted)),
                                        Text('${_scrim!.slotFilled}/${_scrim!.slotTotal} TIM', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        minHeight: 8,
                                        value: _scrim!.slotFilled / _scrim!.slotTotal,
                                        valueColor: const AlwaysStoppedAnimation(BooyahTheme.maroonB),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Text(
                                          '${(_scrim!.slotFilled / _scrim!.slotTotal * 100).toStringAsFixed(0)}% TERISI',
                                          style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Deskripsi
                              _section(
                                'DESKRIPSI',
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(_scrim!.description, style: const TextStyle(fontSize: 12, color: BooyahTheme.textSec, height: 1.6)),
                                ),
                              ),

                              // Peraturan
                              _section(
                                'PERATURAN',
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: BooyahTheme.surface,
                                      border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
                                    ),
                                    child: Column(
                                      children: [
                                        _rule('Daftar tim maksimal 1 jam sebelum pertandingan dimulai'),
                                        _rule('Setiap anggota harus aktif bermain'),
                                        _rule('Dilarang menggunakan cheat atau bug exploit'),
                                        _rule('Keputusan admin bersifat final dan tidak dapat diganggu gugat'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Hadiah
                              _section(
                                'PEMBAGIAN HADIAH',
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Row(
                                    children: [
                                      _prizeBox(
                                        const Icon(Icons.workspace_premium, size: 22, color: BooyahTheme.gold),
                                        'JUARA 1',
                                        'Rp${(_scrim!.prize * 0.5).toInt() ~/ 1000}k',
                                        BooyahTheme.gold,
                                      ),
                                      const SizedBox(width: 8),
                                      _prizeBox(
                                        const Icon(Icons.military_tech, size: 22, color: BooyahTheme.silver),
                                        'JUARA 2',
                                        'Rp${(_scrim!.prize * 0.3).toInt() ~/ 1000}k',
                                        BooyahTheme.silver,
                                      ),
                                      const SizedBox(width: 8),
                                      _prizeBox(
                                        const Icon(Icons.workspace_premium_outlined, size: 22, color: BooyahTheme.bronze),
                                        'JUARA 3',
                                        'Rp${(_scrim!.prize * 0.2).toInt() ~/ 1000}k',
                                        BooyahTheme.bronze,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
    bottomNavigationBar: _scrim == null
        ? null
        : Container(
            padding: const EdgeInsets.all(14),
            color: BooyahTheme.surface,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                ctx,
                AppRoutes.formTim,
                arguments: _scrim, 
              ),
              child: Text('DAFTAR SEKARANG → Rp${_scrim!.fee ~/ 1000}k'),
            ),
        ),
  );

  Widget _infoCell(Widget icon, String label, String val, {Color? valColor}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: BooyahTheme.card, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          icon,
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 8, color: BooyahTheme.textMuted, letterSpacing: 0.5)),
            Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valColor ?? BooyahTheme.textPri)),
          ]),
        ]),
      );

  Widget _section(String title, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: SectionHeader(title: title),
      ),
      child,
      const SizedBox(height: 16),
    ],
  );

  Widget _rule(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('▸ ', style: TextStyle(color: BooyahTheme.maroonB)),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: BooyahTheme.textSec, height: 1.4))),
    ]),
  );

  Widget _prizeBox(Widget medal, String place, String amt, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: BooyahTheme.card, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(children: [
        medal,
        const SizedBox(height: 4),
        Text(place, style: const TextStyle(fontSize: 9, color: BooyahTheme.textMuted, letterSpacing: 0.5)),
        Text(amt, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
      ]),
    ),
  );
}