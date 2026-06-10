// ──────────────────────────────────────────────────────────
// FILE: lib/features/admin/data_pendaftar_screen.dart
// UC-15: Data Pendaftar (READ-ONLY MONITORING DASHBOARD)
// ──────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/models/models.dart';
import '../../services/supabase_service.dart';

class DataPendaftarScreen extends StatefulWidget {
  const DataPendaftarScreen({super.key});

  @override
  State<DataPendaftarScreen> createState() => _DataPendaftarScreenState();
}

class _DataPendaftarScreenState extends State<DataPendaftarScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(
    length: 3,
    vsync: this,
    initialIndex: 0,
  );
  List<Map<String, dynamic>> _rawData = [];
  bool _loading = true;

  // Ambil scrimId dari arguments
  late int scrimId;

  @override
  void initState() {
    super.initState();
    // Ambil scrimId dari Navigator arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrimId = ModalRoute.of(context)!.settings.arguments as int? ?? 1;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await RegistrationService.getByScrim(scrimId);
      setState(() => _rawData = data);
    } catch (e) {
      debugPrint('Error pendaftar: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // Konversi ke PendaftarModel
  List<PendaftarModel> get _allPendaftar => _rawData
      .map(
        (d) => PendaftarModel(
          id: d['id'].toString(),
          teamName: d['team_name'] as String,
          captainId: d['captain_ff_id'] as String,
          paymentMethod: d['payment_method'] as String? ?? '-',
          amount: _fmtRupiah(d['payment_amount'] as int? ?? 0),
          time: d['created_at'] != null ? _fmtTime(d['created_at']) : '-',
          isApproved: d['status'] == 'verified',
          isRejected:
              d['status'] == 'rejected' ||
              d['status'] == 'expired' ||
              d['status'] == 'failed',
        ),
      )
      .toList();

  List<PendaftarModel> get _pending =>
      _allPendaftar.where((d) => !d.isApproved && !d.isRejected).toList();
  List<PendaftarModel> get _approved =>
      _allPendaftar.where((d) => d.isApproved).toList();
  List<PendaftarModel> get _rejected =>
      _allPendaftar.where((d) => d.isRejected).toList();

  String _fmtTime(String iso) {
    final d = DateTime.parse(iso).toLocal();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _fmtRupiah(int amount) {
    final formatter = amount.toString().split('').reversed.toList();
    String result = '';
    for (int i = 0; i < formatter.length; i++) {
      if (i > 0 && i % 3 == 0) {
        result += '.';
      }
      result += formatter[i];
    }
    return 'Rp${result.split('').reversed.join('')}';
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
      title: const Text('DATA PENDAFTAR'),
      actions: [
        const SizedBox(width: 8),
      ],
      bottom: TabBar(
        controller: _tab,
        indicatorColor: BooyahTheme.maroonB,
        labelColor: BooyahTheme.maroonB,
        unselectedLabelColor: BooyahTheme.textMuted,
        labelStyle: const TextStyle(
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        tabs: [
          Tab(text: 'PENDING (${_pending.length})'),
          Tab(text: 'TERVERIFIKASI (${_approved.length})'),
          Tab(text: 'DITOLAK (${_rejected.length})'),
        ],
      ),
    ),
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFB22222)),
          )
        : TabBarView(
            controller: _tab,
            children: [
              _buildList(_pending),
              _buildList(_approved),
              _buildList(_rejected),
            ],
          ),
  );

  Widget _buildList(List<PendaftarModel> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data.',
          style: TextStyle(color: BooyahTheme.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final d = list[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BooyahTheme.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: BooyahTheme.maroon.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: BooyahTheme.maroon.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: BooyahTheme.maroon.withValues(alpha: 0.3),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.sports_esports_rounded,
                    size: 16,
                    color: BooyahTheme.textPri,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.teamName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      d.captainId,
                      style: const TextStyle(
                        fontSize: 10,
                        color: BooyahTheme.textMuted,
                      ),
                    ),
                    Text(
                      '${d.paymentMethod} · ${d.amount} · ${d.time} WIB',
                      style: const TextStyle(
                        fontSize: 10,
                        color: BooyahTheme.yellow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
