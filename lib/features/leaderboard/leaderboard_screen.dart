import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../services/supabase_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  // Detail View State
  List<Map<String, dynamic>> _teams = [];
  bool _detailLoading = true;
  RealtimeChannel? _channel;

  // List View State
  List<Map<String, dynamic>> _myScrims = [];
  List<Map<String, dynamic>> _allScrims = [];
  bool _listLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        _loadDetail(args);
      } else {
        _loadList();
      }
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadDetail(int scrimId) async {
    if (mounted) setState(() => _detailLoading = true);
    try {
      final data = await ResultService.getLeaderboard(scrimId);
      if (mounted) setState(() => _teams = data);
      
      _channel?.unsubscribe();
      _channel = ResultService.subscribeLeaderboard(scrimId, () async {
        final freshData = await ResultService.getLeaderboard(scrimId);
        if (mounted) {
          setState(() => _teams = freshData);
        }
      });
    } catch (e) {
      debugPrint('Error detail leaderboard: $e');
    } finally {
      if (mounted) setState(() => _detailLoading = false);
    }
  }

  Future<void> _loadList() async {
    if (mounted) setState(() => _listLoading = true);
    try {
      // 1. Load all scrims
      final allRes = await Supabase.instance.client
          .from('scrims')
          .select('id, title, scheduled_at, status, mode')
          .isFilter('deleted_at', null)
          .order('scheduled_at', ascending: false);
      
      _allScrims = List<Map<String, dynamic>>.from(allRes);

      // 2. Load joined scrims for current user
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userProfile = await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('uuid', user.id)
            .maybeSingle();
        if (userProfile != null) {
          final int profileId = userProfile['id'];
          final regRes = await Supabase.instance.client
              .from('registrations')
              .select('scrim_id, scrims(id, title, scheduled_at, status, mode)')
              .eq('user_id', profileId)
              .order('created_at', ascending: false);
          
          final uniqueScrims = <int, Map<String, dynamic>>{};
          for (var r in regRes) {
            if (r['scrims'] != null) {
              final s = r['scrims'] as Map<String, dynamic>;
              final sid = s['id'] as int;
              uniqueScrims[sid] = s;
            }
          }
          _myScrims = uniqueScrims.values.toList();
        }
      } else {
        _myScrims = [];
      }
    } catch (e) {
      debugPrint('Error load scrim lists: $e');
    } finally {
      if (mounted) setState(() => _listLoading = false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final args = ModalRoute.of(ctx)?.settings.arguments;
    if (args is int) {
      return _buildDetailView(args);
    } else {
      return _buildListView();
    }
  }

  Widget _buildListView() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('LEADERBOARD'),
          bottom: const TabBar(
            indicatorColor: BooyahTheme.maroonB,
            labelColor: BooyahTheme.textPri,
            unselectedLabelColor: BooyahTheme.textMuted,
            tabs: [
              Tab(text: 'SCRIM SAYA'),
              Tab(text: 'SCRIM UMUM'),
            ],
          ),
        ),
        body: _listLoading
            ? const Center(child: CircularProgressIndicator(color: BooyahTheme.maroon))
            : TabBarView(
                children: [
                  _buildScrimList(_myScrims, 'Belum ada Scrim yang Anda ikuti.'),
                  _buildScrimList(_allScrims, 'Tidak ada Scrim tersedia.'),
                ],
              ),
      ),
    );
  }

  Widget _buildScrimList(List<Map<String, dynamic>> scrims, String emptyMessage) {
    if (scrims.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            emptyMessage,
            style: const TextStyle(
              color: BooyahTheme.textMuted,
              fontFamily: 'Rajdhani',
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      itemCount: scrims.length,
      itemBuilder: (context, index) {
        final scrim = scrims[index];
        final isFinished = scrim['status'] == 'finished';
        
        return Card(
          color: BooyahTheme.card,
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: BooyahTheme.maroon.withValues(alpha: 0.2),
            ),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isFinished 
                    ? BooyahTheme.green.withValues(alpha: 0.1) 
                    : BooyahTheme.maroon.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFinished ? Icons.emoji_events : Icons.sports_esports_outlined,
                color: isFinished ? BooyahTheme.gold : BooyahTheme.textSec,
              ),
            ),
            title: Text(
              scrim['title'] ?? '',
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: BooyahTheme.textPri,
              ),
            ),
            subtitle: Text(
              '${scrim['mode'] == 'battle_royale' ? 'Battle Royale' : 'Clash Squad'} · ${scrim['scheduled_at'] ?? ''}',
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 11,
                color: BooyahTheme.textSec,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: BooyahTheme.textMuted,
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/leaderboard',
                arguments: scrim['id'] as int,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailView(int scrimId) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_teams.isNotEmpty ? _teams[0]['scrim_title'].toString() : 'LEADERBOARD'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: BooyahTheme.maroon.withValues(alpha: 0.2),
              border: Border.all(
                color: BooyahTheme.maroon.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'SCRIM',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: BooyahTheme.maroonB,
              ),
            ),
          ),
        ],
      ),
      body: _detailLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB22222)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Podium
                  if (_teams.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          BooyahTheme.maroonD.withValues(alpha: 0.8),
                          BooyahTheme.bg,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events,
                              color: BooyahTheme.gold,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'TOP 3 SCRIM WARRIORS',
                              style: TextStyle(
                                fontSize: 11,
                                color: BooyahTheme.gold,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.emoji_events,
                              color: BooyahTheme.gold,
                              size: 14,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_teams.length > 1)
                              _podiumItem(
                                _teams[1]['team_name'],
                                '${_teams[1]['total_point']} PTS',
                                BooyahTheme.silver,
                                85,
                                68,
                              ),
                            const SizedBox(width: 8),
                            if (_teams.isNotEmpty)
                              Column(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: BooyahTheme.gold,
                                    size: 24,
                                  ),
                                  _podiumItem(
                                    _teams[0]['team_name'],
                                    '${_teams[0]['total_point']} PTS',
                                    BooyahTheme.gold,
                                    110,
                                    80,
                                  ),
                                ],
                              ),
                            const SizedBox(width: 8),
                            if (_teams.length > 2)
                              _podiumItem(
                                _teams[2]['team_name'],
                                '${_teams[2]['total_point']} PTS',
                                BooyahTheme.bronze,
                                65,
                                56,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Prize banner
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [BooyahTheme.maroon, BooyahTheme.maroonD],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL HADIAH',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white54,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              _fmtRupiah(
                                int.parse(
                                  (_teams.fold<int>(
                                    0,
                                    (sum, t) =>
                                        sum + (t['prize_amount'] as int? ?? 0),
                                  )).toString(),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: BooyahTheme.gold,
                              ),
                            ),
                            const Text(
                              'Dari distribusi hadiah scrim',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_teams.isNotEmpty)
                            _prizeRow(
                              Icons.looks_one,
                              'Juara 1 · 50%',
                              _fmtRupiah(
                                (_teams[0]['prize_amount'] as int?) ?? 0,
                              ),
                              BooyahTheme.gold,
                            ),
                          if (_teams.length > 1)
                            _prizeRow(
                              Icons.looks_two,
                              'Juara 2 · 30%',
                              _fmtRupiah(
                                (_teams[1]['prize_amount'] as int?) ?? 0,
                              ),
                              BooyahTheme.silver,
                            ),
                          if (_teams.length > 2)
                            _prizeRow(
                              Icons.looks_3,
                              'Juara 3 · 20%',
                              _fmtRupiah(
                                (_teams[2]['prize_amount'] as int?) ?? 0,
                              ),
                              BooyahTheme.bronze,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Rankings
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                'RANK',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: BooyahTheme.textMuted,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'TIM',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: BooyahTheme.textMuted,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'POIN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: BooyahTheme.textMuted,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._teams.asMap().entries.map((e) {
                        final idx = e.key;
                        final t = e.value;
                        final rank = idx + 1;
                        final isMe =
                            t['user_id'] ==
                            Supabase.instance.client.auth.currentUser?.id;
                        final rankColors = {
                          1: BooyahTheme.gold,
                          2: BooyahTheme.silver,
                          3: BooyahTheme.bronze,
                        };
                        final ptColor =
                            rankColors[rank] ??
                            (isMe ? BooyahTheme.maroonB : BooyahTheme.textSec);
                        final borderColor = rank == 1
                            ? BooyahTheme.gold
                            : rank == 2
                            ? BooyahTheme.silver
                            : rank == 3
                            ? BooyahTheme.bronze
                            : BooyahTheme.maroon.withValues(alpha: 0.2);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe
                                ? BooyahTheme.maroon.withValues(alpha: 0.1)
                                : BooyahTheme.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isMe ? BooyahTheme.maroonB : borderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '#$rank',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: ptColor,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.sports_esports,
                                      size: 16,
                                      color: BooyahTheme.textSec,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t['team_name'].toString(),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            t['captain_ff_id']?.toString() ?? '',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: BooyahTheme.textMuted,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${t['total_point']}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: ptColor,
                                        ),
                                      ),
                                      Text(
                                        '${t['kills'] ?? 0} Kills',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: BooyahTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  String _fmtRupiah(int amount) {
    if (amount == 0) return 'Rp0';
    final formatter = amount.toString().split('').reversed.toList();
    String result = '';
    for (int i = 0; i < formatter.length; i++) {
      if (i > 0 && i % 3 == 0) result += '.';
      result += formatter[i];
    }
    return 'Rp${result.split('').reversed.join('')}';
  }

  Widget _podiumItem(
    String name,
    String pts,
    Color color,
    double baseH,
    double avaSize,
  ) => Column(
    children: [
      Icon(Icons.sports_esports, size: avaSize * 0.35, color: color),
      Text(
        name,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w700,
          overflow: TextOverflow.ellipsis,
        ),
        maxLines: 1,
      ),
      Text(
        pts,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
      Container(
        width: baseH * 0.8,
        height: baseH,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Text(
            pts.startsWith('1')
                ? '1'
                : pts.startsWith('2')
                ? '2'
                : '3',
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _prizeRow(IconData icon, String label, String amt, Color color) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Colors.white54),
            ),
            const SizedBox(width: 8),
            Text(
              amt,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      );
}
