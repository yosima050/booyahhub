import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../services/supabase_service.dart';

class RiwayatScrimScreen extends StatefulWidget {
  const RiwayatScrimScreen({super.key});

  @override
  State<RiwayatScrimScreen> createState() => _RiwayatScrimScreenState();
}

class _RiwayatScrimScreenState extends State<RiwayatScrimScreen> {
  int _filterIdx = 0;
  final List<String> _filters = ['SEMUA', 'MENUNGGU', 'BERLANGSUNG', 'SELESAI'];
  List<Map<String, dynamic>> _rawData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await RegistrationService.getMyRiwayat();
      setState(() => _rawData = data);
    } catch (e) {
      debugPrint('Error riwayat: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  RiwayatModel _toModel(Map<String, dynamic> d) => RiwayatModel(
    id:         d['registration_id'].toString(),
    scrimTitle: d['scrim_title'] as String? ?? '',
    adminName:  d['admin_name']  as String? ?? '',
    date:       d['scheduled_at'] != null ? _fmtDate(d['scheduled_at']) : '',
    time:       d['scheduled_at'] != null ? _fmtTime(d['scheduled_at']) : '',
    roomId:     d['room_id']     as String? ?? '',
    fee:        d['fee']         as int?    ?? 0,
    status:     _parseStatus(d['reg_status'] as String? ?? ''),
    rank:       d['rank']        as int?,
    points:     d['total_point'] as int?,
  );

  ScrimStatus _parseStatus(String s) {
    switch (s) {
      case 'waiting_verify': return ScrimStatus.menungguVerifikasi;
      case 'waiting_room_id': return ScrimStatus.menungguRoomId;
      case 'ongoing':         return ScrimStatus.berlangsung;
      case 'finished':        return ScrimStatus.selesai;
      default:                return ScrimStatus.menungguVerifikasi;
    }
  }

  List<RiwayatModel> get _filtered {
    final all = _rawData.map(_toModel).toList();
    if (_filterIdx == 0) return all;
    final map = [null, ScrimStatus.menungguVerifikasi, ScrimStatus.berlangsung, ScrimStatus.selesai];
    return all.where((r) => r.status == map[_filterIdx]).toList();
  }

  String _fmtDate(String iso) {
    final d = DateTime.parse(iso).toLocal();
    const m = ['','Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agt','Sep','Okt','Nov','Des'];
    return '${d.day} ${m[d.month]} ${d.year}';
  }
  String _fmtTime(String iso) {
    final d = DateTime.parse(iso).toLocal();
    return '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')} WIB';
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(title: const Text('RIWAYAT SCRIM')),
    body: Column(
      children: [
        // Filter chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            itemCount: _filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 7),
            itemBuilder: (_, i) {
              final active = _filterIdx == i;
              return GestureDetector(
                onTap: () => setState(() => _filterIdx = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: active ? BooyahTheme.maroon : BooyahTheme.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: active ? BooyahTheme.maroon : BooyahTheme.maroon.withValues(alpha: 0.3)),
                  ),
                  child: Text(_filters[i], style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: active ? Colors.white : BooyahTheme.textMuted,
                  )),
                ),
              );
            },
          ),
        ),

        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFB22222)))
              : _filtered.isEmpty
                  ? const Center(child: Text('Belum ada riwayat scrim.', style: TextStyle(color: BooyahTheme.textMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _buildCard(_filtered[i]),
                    ),
        ),
      ],
    ),
  );

  Widget _buildCard(RiwayatModel r) {
    final steps = _buildSteps(r);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: BooyahTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusBorderColor(r.status).withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('🎮', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.scrimTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text('${r.adminName} · ${r.date} · ${r.time}',
                      style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted)),
                  ],
                )),
                StatusBadge(label: _statusLabel(r.status), color: _statusBorderColor(r.status)),
              ],
            ),
          ),
          // Timeline
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Column(children: steps),
          ),
          // Rank result (if done)
          if (r.status == ScrimStatus.selesai && r.rank != null)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: BooyahTheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Peringkat Akhir', style: TextStyle(fontSize: 11, color: BooyahTheme.textMuted)),
                  Text('#${r.rank} · ${r.points} PTS',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: BooyahTheme.bronze)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildSteps(RiwayatModel r) {
    final s = r.status;
    return [
      TimelineStep(title: 'Booking Dilakukan',       subtitle: r.date,  isDone: true, stepLabel: '1'),
      TimelineStep(
        title: 'Pembayaran Dikonfirmasi',
        subtitle: s == ScrimStatus.menungguVerifikasi ? 'Menunggu verifikasi admin' : 'Terverifikasi',
        isDone: s != ScrimStatus.menungguVerifikasi,
        isActive: s == ScrimStatus.menungguVerifikasi,
        stepLabel: '2',
      ),
      TimelineStep(
        title: 'Room ID Dikirim',
        subtitle: r.roomId.isNotEmpty ? 'Room: ${r.roomId}' : 'Belum tersedia',
        isDone: r.roomId.isNotEmpty,
        isActive: s == ScrimStatus.menungguRoomId,
        stepLabel: '3',
      ),
      TimelineStep(
        title: s == ScrimStatus.selesai ? 'Scrim Selesai' : 'Scrim Berlangsung',
        subtitle: s == ScrimStatus.berlangsung ? 'Sedang berlangsung' : '',
        isDone: s == ScrimStatus.selesai,
        isActive: s == ScrimStatus.berlangsung,
        stepLabel: '4',
        isLast: true,
      ),
    ];
  }

  Color _statusBorderColor(ScrimStatus s) {
    switch (s) {
      case ScrimStatus.berlangsung:       return BooyahTheme.maroonGlow;
      case ScrimStatus.menungguVerifikasi: return BooyahTheme.yellow;
      case ScrimStatus.selesai:           return BooyahTheme.green;
      default: return BooyahTheme.maroon;
    }
  }

  String _statusLabel(ScrimStatus s) {
    switch (s) {
      case ScrimStatus.berlangsung:       return 'BERLANGSUNG';
      case ScrimStatus.menungguVerifikasi: return 'VERIFIKASI';
      case ScrimStatus.menungguRoomId:    return 'ROOM ID';
      case ScrimStatus.selesai:           return 'SELESAI';
    }
  }
}
