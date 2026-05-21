import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../services/supabase_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifs = [];
  bool _loading = true;
  RealtimeChannel? _channel;

@override
  void initState() {
    super.initState();
    _load();
    
    // Safely check for the user before subscribing to Realtime
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _channel = NotificationService.subscribeNotifications(
        user.id,
        (newNotif) {
          if (mounted) {
            setState(() => _notifs.insert(0, newNotif));
          }
        },
      );
    } else {
      debugPrint('Warning: User is null, skipping realtime subscription.');
    }
  }

  @override
  void dispose() {
    // Only unsubscribe if the channel was successfully created
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await NotificationService.getAll();
      setState(() => _notifs = data);
    } catch (e) {
      debugPrint('Error notifs: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _markRead(int i) async {
    final id = _notifs[i]['id'] as int;
    setState(() => _notifs[i]['is_read'] = true);
    await NotificationService.markRead(id);
  }

  void _markAllRead() async {
    setState(() { for (final n in _notifs) {
      n['is_read'] = true;
    } });
    await NotificationService.markAllRead();
  }

  int get _unreadCount => _notifs.where((n) => n['is_read'] == false).length;

  Color _getTypeColor(String type) {
    switch (type) {
      case 'room_id':        return BooyahTheme.maroonGlow;
      case 'payment':        return BooyahTheme.green;
      case 'result':         return BooyahTheme.gold;
      case 'claim':          return BooyahTheme.yellow;
      case 'schedule':       return BooyahTheme.yellow;
      case 'booking':        return BooyahTheme.maroonB;
      case 'announcement':   return BooyahTheme.maroon;
      default:               return BooyahTheme.textMuted;
    }
  }

  String _getIcon(String type) {
    switch (type) {
      case 'room_id':      return '🔴';
      case 'payment':      return '✅';
      case 'result':       return '🏆';
      case 'claim':        return '💰';
      case 'schedule':     return '⚠️';
      case 'booking':      return '🎮';
      case 'announcement': return '📢';
      default:             return '📝';
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
      title: Row(children: [
        const Text('NOTIFIKASI'),
        if (_unreadCount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: BooyahTheme.maroon, borderRadius: BorderRadius.circular(10)),
            child: Text('$_unreadCount', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ]),
      actions: [
        TextButton(onPressed: _markAllRead,
          child: const Text('TANDAI SEMUA', style: TextStyle(fontSize: 10, color: BooyahTheme.maroonB, fontWeight: FontWeight.w700))),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFB22222)))
        : _notifs.isEmpty
            ? const Center(child: Text('Tidak ada notifikasi.', style: TextStyle(color: BooyahTheme.textMuted)))
            : ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _notifs.length,
                itemBuilder: (_, i) {
                  final n = _notifs[i];
                  final unread = n['is_read'] != true;
                  final type = n['type'] as String? ?? 'notification';
                  final color = _getTypeColor(type);
                  final ico = _getIcon(type);
                  return GestureDetector(
                    onTap: () => _markRead(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 9),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: unread ? color.withValues(alpha: 0.05) : BooyahTheme.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: unread ? color.withValues(alpha: 0.4) : BooyahTheme.maroon.withValues(alpha: 0.15)),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(ico, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n['title'] as String? ?? '', style: TextStyle(fontSize: 12, fontWeight: unread ? FontWeight.w700 : FontWeight.w600, color: unread ? color : BooyahTheme.textSec)),
                          Text(n['message'] as String? ?? '', style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(_formatTime(n['created_at'] as String? ?? ''), style: const TextStyle(fontSize: 9, color: BooyahTheme.textMuted)),
                        ])),
                        if (unread)
                          Container(width: 8, height: 8, margin: const EdgeInsets.only(left: 8, top: 4), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      ]),
                    ),
                  );
                },
              ),
  );

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inMinutes < 1) return 'baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
      if (diff.inHours < 24) return '${diff.inHours}h lalu';
      if (diff.inDays < 7) return '${diff.inDays}d lalu';
      return dt.toString().split(' ')[0];
    } catch (e) {
      return '';
    }
  }
}
