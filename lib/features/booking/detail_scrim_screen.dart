import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  Map<String, dynamic>? _myReg;
  String? _registrationStatus;

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

      // Cek status registrasi user untuk scrim ini
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userProfile = await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('uuid', user.id)
            .single();
        final int buyerId = userProfile['id'];

        final regData = await Supabase.instance.client
            .from('registrations')
            .select('*, team_members(ff_id)')
            .eq('scrim_id', int.parse(scrimId))
            .eq('user_id', buyerId)
            .maybeSingle();

        if (regData != null) {
          setState(() {
            _myReg = regData;
            _registrationStatus = regData['status'] as String?;
          });
        } else {
          setState(() {
            _myReg = null;
            _registrationStatus = null;
          });
        }
      }
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
                          expandedHeight: 160,
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
                                padding: const EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _scrim!.title,
                                        style: const TextStyle(
                                          fontFamily: 'Orbitron',
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      children: [
                                        // Bagian Admin
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.person, size: 14, color: Colors.white70),
                                            const SizedBox(width: 4),
                                            Text(
                                              _scrim!.adminName,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        
                                        // Bagian Waktu/Jam
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time, size: 14, color: Colors.white70),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${_scrim!.date} · ${_scrim!.time}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ],
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
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final width = constraints.maxWidth;
                                    final cardWidth = (width - 8) / 2;
                                    final ratio = (cardWidth / 56).clamp(1.5, 3.5);
                                    return GridView.count(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                      childAspectRatio: ratio,
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
                                    );
                                  },
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
                                        const Text('PERKEMBANGAN SLOT', style: TextStyle(fontSize: 11, color: BooyahTheme.textMuted)),
                                        Text('${_scrim!.slotFilled}/${_scrim!.slotTotal} TIM', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
                                          style: const TextStyle(fontSize: 11, color: BooyahTheme.textMuted),
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
                                  child: Text(_scrim!.description, style: const TextStyle(fontSize: 14, color: BooyahTheme.textSec, height: 1.6)),
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
            child: _buildActionButton(ctx),
          ),
  );

  Widget _buildActionButton(BuildContext ctx) {
    if (_registrationStatus == 'verified') {
      return ElevatedButton(
        onPressed: null, // Disabled
        style: ElevatedButton.styleFrom(
          backgroundColor: BooyahTheme.green.withValues(alpha: 0.35),
          disabledBackgroundColor: BooyahTheme.green.withValues(alpha: 0.35),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: BooyahTheme.green, size: 18),
            SizedBox(width: 8),
            Text(
              'ANDA SUDAH TERDAFTAR (TERVERIFIKASI)',
              style: TextStyle(color: BooyahTheme.green, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
      );
    }

    if (_registrationStatus == 'waiting_verify') {
      return ElevatedButton(
        onPressed: null, // Disabled
        style: ElevatedButton.styleFrom(
          backgroundColor: BooyahTheme.gold.withValues(alpha: 0.35),
          disabledBackgroundColor: BooyahTheme.gold.withValues(alpha: 0.35),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pending_actions_rounded, color: BooyahTheme.gold, size: 18),
            SizedBox(width: 8),
            Text(
              'MENUNGGU VERIFIKASI PEMBAYARAN',
              style: TextStyle(color: BooyahTheme.gold, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
      );
    }

    if (_registrationStatus == 'pending_payment' && _myReg != null) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  ctx,
                  AppRoutes.pembayaran,
                  arguments: {
                    'scrim': _scrim,
                    'team_name': _myReg!['team_name'],
                    'captain_ff_id': _myReg!['captain_ff_id'],
                    'phone': _myReg!['phone'],
                    'members': List<String>.from((_myReg!['team_members'] as List? ?? []).map((m) => m['ff_id'] as String)),
                  },
                ).then((_) => _loadScrim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BooyahTheme.gold,
              ),
              child: const Text('LANJUTKAN PEMBAYARAN'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(
                  ctx,
                  AppRoutes.formTim,
                  arguments: _scrim,
                ).then((_) => _loadScrim());
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: BooyahTheme.maroon, width: 1.5),
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Icon(Icons.edit, color: BooyahTheme.maroonB),
            ),
          ),
        ],
      );
    }

    // Default: Belum daftar
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(
        ctx,
        AppRoutes.formTim,
        arguments: _scrim, 
      ).then((_) => _loadScrim()),
      child: Text('DAFTAR SEKARANG → Rp${_scrim!.fee ~/ 1000}k'),
    );
  }

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: BooyahTheme.textMuted, letterSpacing: 0.5),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    val,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valColor ?? BooyahTheme.textPri),
                  ),
                ),
              ],
            ),
          ),
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
      Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: BooyahTheme.textSec, height: 1.4))),
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
        Text(place, style: const TextStyle(fontSize: 11, color: BooyahTheme.textMuted, letterSpacing: 0.5)),
        Text(amt, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ]),
    ),
  );
}