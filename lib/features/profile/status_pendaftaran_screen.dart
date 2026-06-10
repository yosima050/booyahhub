import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../services/supabase_service.dart';

class StatusPendaftaranScreen extends StatefulWidget {
  const StatusPendaftaranScreen({super.key});
  @override
  State<StatusPendaftaranScreen> createState() =>
      _StatusPendaftaranScreenState();
}

class _StatusPendaftaranScreenState extends State<StatusPendaftaranScreen> {
  List<Map<String, dynamic>> _registrations = [];
  bool _loading = true;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadRegistrations() async {
    try {
      if (mounted) {
        setState(() => _loading = true);
      }
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await RegistrationService.getMyRiwayat();
        if (mounted) {
          setState(() => _registrations = data);
        }
        _setupRealtimeSubscription(user.id);
      }
    } catch (e) {
      debugPrint('Error loading registrations: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadRegistrationsSilent() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await RegistrationService.getMyRiwayat();
        if (mounted) {
          setState(() => _registrations = data);
        }
      }
    } catch (e) {
      debugPrint('Error loading registrations silently: $e');
    }
  }

  void _setupRealtimeSubscription(String userUuid) async {
    _realtimeChannel?.unsubscribe();
    try {
      final profile = await UserService.getUserProfile(userUuid);
      final int userBigId = profile['id'] as int;
      _realtimeChannel = RegistrationService.subscribeMyStatus(
        userBigId.toString(),
        (payload) {
          debugPrint('Realtime status pendaftaran updated: $payload');
          _loadRegistrationsSilent();
        },
      );
    } catch (e) {
      debugPrint('Error setting up realtime subscription: $e');
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(title: const Text('STATUS PENDAFTARAN')),
    body: RefreshIndicator(
      onRefresh: _loadRegistrations,
      color: BooyahTheme.maroon,
      backgroundColor: BooyahTheme.card,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB22222)),
            )
          : _registrations.isEmpty
          ? const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Text(
                    'Belum ada pendaftaran scrim.',
                    style: TextStyle(color: BooyahTheme.textMuted),
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'PENDAFTARAN AKTIF'),
                  ..._registrations.map(
                    (reg) => _buildStatusCard(
                      title: reg['scrim_title'] as String? ?? 'Unknown',
                      admin:
                          '${reg['admin_name'] ?? 'Admin'} · ${_fmtDate(reg['scheduled_at'])} · ${_fmtTime(reg['scheduled_at'])}',
                      regStatus: reg['reg_status'] as String? ?? 'unknown',
                      roomId: reg['room_id'] as String?,
                      borderColor: _getStatusColor(
                        reg['reg_status'] as String? ?? 'unknown',
                      ),
                      statusLabel: _getStatusLabel(
                        reg['reg_status'] as String? ?? 'unknown',
                      ),
                      statusColor: _getStatusColor(
                        reg['reg_status'] as String? ?? 'unknown',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    ),
  );

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    final d = DateTime.parse(iso).toLocal();
    const m = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${m[d.month]}';
  }

  String _fmtTime(String? iso) {
    if (iso == null) return '';
    final d = DateTime.parse(iso).toLocal();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
      case 'waiting_room_id':
        return BooyahTheme.yellow;
      case 'waiting_verify':
        return BooyahTheme.yellow;
      case 'ongoing':
        return BooyahTheme.maroonGlow;
      case 'finished':
        return BooyahTheme.green;
      default:
        return BooyahTheme.textMuted;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'verified':
      case 'waiting_room_id':
        return 'MENUNGGU ROOM ID';
      case 'waiting_verify':
        return 'VERIFIKASI';
      case 'ongoing':
        return 'BERLANGSUNG';
      case 'finished':
        return 'SELESAI';
      default:
        return status.toUpperCase();
    }
  }

  static Widget _buildStatusCard({
    required String title,
    required String admin,
    required String regStatus,
    required String? roomId,
    required Color borderColor,
    required String statusLabel,
    required Color statusColor,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: BooyahTheme.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor.withValues(alpha: 0.35)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🎮', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    admin,
                    style: const TextStyle(
                      fontSize: 10,
                      color: BooyahTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            StatusBadge(label: statusLabel, color: statusColor),
          ],
        ),
        const SizedBox(height: 14),
        TimelineStep(
          title: 'Booking Dilakukan',
          subtitle: 'Selesai',
          isDone: true,
          isActive: false,
          stepLabel: '1',
          isLast: false,
        ),
        TimelineStep(
          title: 'Pembayaran',
          subtitle: regStatus == 'pending_payment'
              ? 'Menunggu Pembayaran'
              : (regStatus == 'verified' ||
                    regStatus == 'waiting_room_id' ||
                    regStatus == 'ongoing' ||
                    regStatus == 'finished')
              ? 'Dikonfirmasi'
              : 'Gagal / Kadaluarsa',
          isDone:
              regStatus == 'verified' ||
              regStatus == 'waiting_room_id' ||
              regStatus == 'ongoing' ||
              regStatus == 'finished',
          isActive: regStatus == 'pending_payment',
          stepLabel: '2',
          isLast: true,
        ),
      ],
    ),
  );
}
