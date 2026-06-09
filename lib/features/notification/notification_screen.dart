import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await NotificationService.getAll();
      if (!mounted) return;
      setState(() {
        _notifs = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error notifs: $e');
      if (!mounted) return;
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
      case 'room_id':
      case 'room_info':      return BooyahTheme.maroonGlow;
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
      case 'room_id':
      case 'room_info':    return '🔴';
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
                    onTap: () {
                      _markRead(i);
                      _showDetailDialog(context, n);
                    },
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

  void _showDetailDialog(BuildContext context, Map<String, dynamic> notif) {
    final title = notif['title'] as String? ?? 'Notifikasi';
    final message = notif['message'] as String? ?? '';
    final type = notif['type'] as String? ?? '';
    final isRoomInfo = type == 'room_id' || type == 'room_info' || message.toLowerCase().contains('room');

    String? roomId;
    String? roomPass;

    if (isRoomInfo) {
      if (notif['data'] != null && notif['data'] is Map) {
        final dataMap = notif['data'] as Map;
        roomId = dataMap['room_id']?.toString();
        roomPass = dataMap['room_password']?.toString();
      }

      if ((roomId == null || roomId.isEmpty) && message.isNotEmpty) {
        final regRoom = RegExp(r'Room\s*ID\s*:\s*([^\s·\n,]+)', caseSensitive: false);
        final matchRoom = regRoom.firstMatch(message);
        if (matchRoom != null) {
          roomId = matchRoom.group(1);
        }
      }

      if ((roomPass == null || roomPass.isEmpty) && message.isNotEmpty) {
        final regPass = RegExp(r'(?:Password|Pass)\s*:\s*([^\s·\n,]+)', caseSensitive: false);
        final matchPass = regPass.firstMatch(message);
        if (matchPass != null) {
          roomPass = matchPass.group(1);
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BooyahTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white10),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 12, color: BooyahTheme.textSec, height: 1.5),
            ),
            if (roomId != null && roomId.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ROOM ID', style: TextStyle(fontSize: 8, color: BooyahTheme.textMuted, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(roomId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: BooyahTheme.gold),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: roomId!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚡ Room ID berhasil disalin!'),
                            backgroundColor: BooyahTheme.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            if (roomPass != null && roomPass.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ROOM PASSWORD', style: TextStyle(fontSize: 8, color: BooyahTheme.textMuted, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(roomPass, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: BooyahTheme.gold),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: roomPass!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚡ Room Password berhasil disalin!'),
                            backgroundColor: BooyahTheme.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'TUTUP',
              style: TextStyle(color: BooyahTheme.textMuted, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
