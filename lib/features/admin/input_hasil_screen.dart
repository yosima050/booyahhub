// ──────────────────────────────────────────────────────────
// FILE: lib/features/admin/input_hasil_screen.dart
// UC-08: Input Hasil Pertandingan
// ──────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../services/supabase_service.dart';

// Model untuk data player per tim
class PlayerScoreModel {
  String name;
  int kills;
  PlayerScoreModel({required this.name, this.kills = 0});
}

class InputHasilScreen extends StatefulWidget {
  const InputHasilScreen({super.key});

  @override
  State<InputHasilScreen> createState() => _InputHasilScreenState();
}

class _InputHasilScreenState extends State<InputHasilScreen> {
  List<TeamScoreModel> _teams = [];
  bool _loading = true;
  String? _error;
  late int scrimId;
  Map<String, dynamic>? _scrimData;

  // Map teamId -> list of players
  final Map<String, List<PlayerScoreModel>> _playersMap = {};
  // Track which teams are expanded
  final Set<String> _expandedTeams = {};
  final Map<String, TextEditingController> _teamKillsControllers = {};
  // Controllers for team placement ranks to sync changes
  final Map<String, TextEditingController> _teamPlacementControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrimId = ModalRoute.of(context)!.settings.arguments as int? ?? 1;
      _loadTeams();
    });
  }

  @override
  void dispose() {
    for (final ctrl in _teamKillsControllers.values) {
      ctrl.dispose();
    }
    for (final ctrl in _teamPlacementControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() => _loading = true);
    try {
      // 1. Fetch scrim details
      final scrim = await ScrimService.getById(scrimId.toString());
      _scrimData = scrim;

      // 2. Fetch existing match results
      final existingResults = await Supabase.instance.client
          .from('match_results')
          .select()
          .eq('scrim_id', scrimId);
          
      final Map<int, Map<String, dynamic>> resultsMap = {
        for (var r in existingResults) r['registration_id'] as int: r
      };

      // 3. Ambil tim yang sudah verified/ongoing/waiting_room_id/finished di scrim ini
      final data = await RegistrationService.getByScrim(scrimId);
      setState(() {
        _teams = data
            .where((d) =>
                d['status'] == 'verified' ||
                d['status'] == 'ongoing' ||
                d['status'] == 'waiting_room_id' ||
                d['status'] == 'finished')
            .map(
              (d) {
                final int regId = d['id'] as int;
                final existing = resultsMap[regId];
                final String teamId = regId.toString();
                final int kills = existing?['kills'] as int? ?? 0;
                final int placement = existing?['placement'] as int? ?? 1;
                
                // Initialize controllers
                _teamKillsControllers[teamId] = TextEditingController(text: '$kills');
                _teamPlacementControllers[teamId] = TextEditingController(text: '$placement');
                
                return TeamScoreModel(
                  id: teamId,
                  teamName: d['team_name'] as String,
                  icon: '',
                  placement: placement,
                  kills: kills,
                );
              },
            )
            .toList();

        // Inisialisasi players map untuk setiap tim dari team_members terdaftar
        for (final d in data) {
          final String status = d['status'] as String? ?? '';
          if (status == 'verified' || status == 'ongoing' || status == 'waiting_room_id' || status == 'finished') {
            final String teamId = d['id'].toString();
            final String captainFfId = d['captain_ff_id'] as String? ?? 'Kapten';
            final List<dynamic> members = d['team_members'] as List? ?? [];
            
            final List<PlayerScoreModel> roster = [];
            // Kapten selalu di indeks 0
            roster.add(PlayerScoreModel(name: captainFfId, kills: 0));
            // Anggota tim lainnya
            roster.addAll(members.map((m) {
              final String ffId = m['ff_id'] as String? ?? 'Player';
              return PlayerScoreModel(name: ffId, kills: 0);
            }));
            
            _playersMap[teamId] = roster;
          }
        }
      });
    } catch (e) {
      debugPrint('Error load teams: $e');
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  List<TeamScoreModel> get _sorted =>
      [..._teams]..sort((a, b) => b.totalPoint.compareTo(a.totalPoint));

  void _saveResults() async {
    // UC-08 Langkah 5a: Validasi nilai negatif
    for (final t in _teams) {
      if (t.kills < 0 || t.placement < 1) {
        setState(() => _error = 'Nilai tidak boleh negatif atau nol!');
        return;
      }
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ResultService.submitResults(
        scrimId: scrimId,
        results: _teams
            .map(
              (t) => {
                'registration_id': int.parse(t.id),
                'team_name': t.teamName,
                'placement': t.placement,
                'kills': t.kills,
                'players': (_playersMap[t.id] ?? [])
                    .where((p) => p.name.trim().isNotEmpty)
                    .map((p) => {'name': p.name.trim(), 'kills': p.kills})
                    .toList(),
              },
            )
            .toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Leaderboard diperbarui & hadiah dialokasikan!'),
              ],
            ),
            backgroundColor: BooyahTheme.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('$e')),
              ],
            ),
            backgroundColor: const Color(0xFFFF1744),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
      title: const Text('INPUT HASIL'),
      actions: [
        const SizedBox(width: 8),
      ],
    ),
    body: Column(
      children: [
        // Scrim info banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: BooyahTheme.surface,
          child: Row(
            children: [
              const Icon(
                Icons.sports_esports,
                size: 16,
                color: BooyahTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                '${_scrimData?['title'] ?? 'BOOYAH CUP'} · ${_scrimData?['scheduled_at'] ?? ''} · ${_teams.length} Tim',
                style: const TextStyle(
                  fontSize: 11,
                  color: BooyahTheme.textMuted,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sistem poin
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BooyahTheme.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: BooyahTheme.maroon.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SISTEM POIN FREE FIRE SCRIM',
                        style: TextStyle(
                          fontSize: 10,
                          color: BooyahTheme.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _pointChip('#1', '12'),
                          _pointChip('#2', '9'),
                          _pointChip('#3', '7'),
                          _pointChip('#4', '5'),
                          _pointChip('#5+', '2'),
                          _pointChip('Kill', '1'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Total = Poin Placement + (Kill × 1)',
                        style: TextStyle(
                          fontSize: 10,
                          color: BooyahTheme.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Input per tim
                const SectionHeader(title: 'INPUT PER TIM'),
                Container(
                  decoration: BoxDecoration(
                    color: BooyahTheme.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: BooyahTheme.maroon.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                        child: Row(
                          children: const [
                            SizedBox(width: 24),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'TIM',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: BooyahTheme.textMuted,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            SizedBox(width: 4),
                            SizedBox(
                              width: 72,
                              child: Text(
                                'PERINGKAT (#)',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: BooyahTheme.textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: 4),
                            SizedBox(
                              width: 52,
                              child: Text(
                                'KILLS',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: BooyahTheme.textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: 4),
                            SizedBox(
                              width: 44,
                              child: Text(
                                'TOTAL',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: BooyahTheme.textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white12),
                      ..._teams.map((t) => _buildScoreRow(t)),
                    ],
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: BooyahTheme.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: BooyahTheme.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: BooyahTheme.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: BooyahTheme.red,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Live preview leaderboard
                const SectionHeader(title: 'PREVIEW LEADERBOARD'),
                Container(
                  decoration: BoxDecoration(
                    color: BooyahTheme.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: BooyahTheme.maroon.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: _sorted.asMap().entries.map((e) {
                      final rank = e.key + 1;
                      final t = e.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.04),
                            ),
                          ),
                          color: rank <= 3
                              ? BooyahTheme.maroon.withValues(alpha: 0.06)
                              : null,
                        ),
                        child: Row(
                          children: [
                            _rankBadge(rank),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color: BooyahTheme.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t.teamName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${t.kills}K',
                              style: const TextStyle(
                                fontSize: 10,
                                color: BooyahTheme.textMuted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${t.totalPoint} PTS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: rank == 1
                                    ? BooyahTheme.gold
                                    : rank == 2
                                    ? BooyahTheme.silver
                                    : rank == 3
                                    ? BooyahTheme.bronze
                                    : BooyahTheme.textSec,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: BooyahButton(
            label: 'SIMPAN HASIL & UPDATE LEADERBOARD',
            onTap: _saveResults,
            isLoading: _loading,
            color: const Color(0xFF1a5c1a),
          ),
        ),
      ],
    ),
  );

  Widget _buildScoreRow(TeamScoreModel t) {
    final idx = _teams.indexOf(t);
    final isExpanded = _expandedTeams.contains(t.id);
    final players = _playersMap[t.id] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row tim utama
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: isExpanded ? 0.0 : 0.04),
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 16,
                color: BooyahTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.teamName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Placement rank input
              SizedBox(
                width: 72,
                child: TextFormField(
                  controller: _teamPlacementControllers[t.id],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 13,
                    color: BooyahTheme.textPri,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        color: BooyahTheme.maroon.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  onChanged: (v) {
                    final rank = int.tryParse(v) ?? 1;
                    setState(() {
                      _teams[idx].placement = rank.clamp(1, 99);
                    });
                  },
                ),
              ),
              const SizedBox(width: 4),
              // Kills input
              SizedBox(
                width: 52,
                child: TextFormField(
                  controller: _teamKillsControllers[t.id],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 13,
                    color: BooyahTheme.textPri,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        color: BooyahTheme.maroon.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  onChanged: (v) {
                    final kl = int.tryParse(v) ?? 0;
                    setState(() {
                      _teams[idx].kills = kl;
                    });
                  },
                ),
              ),
              const SizedBox(width: 4),
              // Total (auto-calculated)
              SizedBox(
                width: 44,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: BooyahTheme.surface,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '${t.totalPoint}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: BooyahTheme.gold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Toggle expand player
              GestureDetector(
                onTap: () => setState(() {
                  if (isExpanded) {
                    _expandedTeams.remove(t.id);
                  } else {
                    _expandedTeams.add(t.id);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: BooyahTheme.maroon.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.person_add_alt_1,
                    size: 16,
                    color: BooyahTheme.yellow,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Section input player (expanded)
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              color: BooyahTheme.bg.withValues(alpha: 0.6),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header player section
                Row(
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      size: 12,
                      color: BooyahTheme.yellow,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'DATA PLAYER',
                      style: TextStyle(
                        fontSize: 9,
                        color: BooyahTheme.yellow,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // (Daftar anggota ditentukan saat pendaftaran)
                  ],
                ),
                const SizedBox(height: 6),

                // Header kolom player
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: const [
                      SizedBox(width: 20),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'NAMA PLAYER',
                          style: TextStyle(
                            fontSize: 8,
                            color: BooyahTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      SizedBox(
                        width: 52,
                        child: Text(
                          'KILLS',
                          style: TextStyle(
                            fontSize: 8,
                            color: BooyahTheme.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Removed width: 24 spacing since delete button is removed
                    ],
                  ),
                ),

                // List player rows
                ...players.asMap().entries.map((entry) {
                  final pIdx = entry.key;
                  final player = entry.value;
                  final isCaptain = pIdx == 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        // Nomor player
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCaptain 
                                ? BooyahTheme.gold.withValues(alpha: 0.2)
                                : BooyahTheme.maroon.withValues(alpha: 0.25),
                          ),
                          child: Center(
                            child: Text(
                              '${pIdx + 1}',
                              style: TextStyle(
                                fontSize: 9,
                                color: isCaptain ? BooyahTheme.gold : BooyahTheme.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Read-only nama player
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isCaptain 
                                  ? BooyahTheme.maroon.withValues(alpha: 0.1) 
                                  : BooyahTheme.surface,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: isCaptain 
                                    ? BooyahTheme.gold.withValues(alpha: 0.4) 
                                    : BooyahTheme.maroon.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                if (isCaptain) ...[
                                  const Icon(
                                    Icons.star_rounded, 
                                    color: BooyahTheme.gold, 
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: Text(
                                    player.name + (isCaptain ? ' (Kapten)' : ''),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isCaptain ? BooyahTheme.gold : BooyahTheme.textPri,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Input kills player
                        SizedBox(
                          width: 52,
                          child: TextFormField(
                            initialValue: '${player.kills}',
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 12,
                              color: BooyahTheme.textPri,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 7,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                borderSide: BorderSide(
                                  color: BooyahTheme.maroon.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                borderSide: BorderSide(
                                  color: BooyahTheme.maroon.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                            ),
                             onChanged: (v) {
                               setState(() {
                                 player.kills = int.tryParse(v) ?? 0;
                                 final totalKills = players.fold<int>(0, (sum, p) => sum + p.kills);
                                 _teams[idx].kills = totalKills;
                                 _teamKillsControllers[t.id]?.text = '$totalKills';
                               });
                             },
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
    );
  }

  Widget _pointChip(String place, String pts) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 3),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: BooyahTheme.bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(
            place,
            style: const TextStyle(fontSize: 9, color: BooyahTheme.textMuted),
          ),
          Text(
            '+$pts',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: BooyahTheme.gold,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _rankBadge(int rank) {
    final colors = {
      1: BooyahTheme.gold,
      2: BooyahTheme.silver,
      3: BooyahTheme.bronze,
    };
    final color = colors[rank] ?? BooyahTheme.textMuted;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}
