// ──────────────────────────────────────────────────────────
// FILE: lib/features/admin/input_hasil_screen.dart
// UC-08: Input Hasil Pertandingan
// ──────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../services/supabase_service.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrimId = ModalRoute.of(context)!.settings.arguments as int? ?? 1;
      _loadTeams();
    });
  }

  Future<void> _loadTeams() async {
    setState(() => _loading = true);
    try {
      // Ambil tim yang sudah verified di scrim ini
      final data = await RegistrationService.getByScrim(scrimId);
      setState(() {
        _teams = data
          .where((d) => d['status'] == 'verified' || d['status'] == 'ongoing')
          .map((d) => TeamScoreModel(
            id:        d['id'].toString(),
            teamName:  d['team_name'] as String,
            icon:      '🎮',
            placement: 1,
            kills:     0,
          )).toList();
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
    setState(() { _loading = true; _error = null; });
    try {
      await ResultService.submitResults(
        scrimId: scrimId,
        results: _teams.map((t) => {
          'registration_id': int.parse(t.id),
          'team_name':       t.teamName,
          'placement':       t.placement,
          'kills':           t.kills,
        }).toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Leaderboard diperbarui & hadiah dialokasikan!'),
            backgroundColor: BooyahTheme.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: const Color(0xFFFF1744)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(title: const Text('INPUT HASIL'),
      actions: [Chip(label: const Text('ADMIN', style: TextStyle(fontSize: 9)),
        backgroundColor: BooyahTheme.yellow.withOpacity(0.15),
        labelStyle: const TextStyle(color: BooyahTheme.yellow, fontWeight: FontWeight.w700),
      ), const SizedBox(width: 8)]),
    body: Column(
      children: [
        // Scrim info banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: BooyahTheme.surface,
          child: const Row(children: [
            Text('🎮', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Text('BOOYAH CUP S7 · 11 Mar · 19:00 WIB · 6 Tim',
              style: TextStyle(fontSize: 11, color: BooyahTheme.textMuted)),
          ]),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Sistem poin
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BooyahTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BooyahTheme.maroon.withOpacity(0.25)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('SISTEM POIN FREE FIRE SCRIM',
                    style: TextStyle(fontSize: 10, color: BooyahTheme.textMuted, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _pointChip('🥇 #1', '12'),
                    _pointChip('🥈 #2', '9'),
                    _pointChip('🥉 #3', '7'),
                    _pointChip('#4', '5'),
                    _pointChip('#5+', '2'),
                    _pointChip('Kill', '1'),
                  ]),
                  const SizedBox(height: 6),
                  const Text('Total = Poin Placement + (Kill × 1)',
                    style: TextStyle(fontSize: 10, color: BooyahTheme.textMuted, fontStyle: FontStyle.italic)),
                ]),
              ),
              const SizedBox(height: 14),

              // Input per tim
              const SectionHeader(title: 'INPUT PER TIM'),
              Container(
                decoration: BoxDecoration(
                  color: BooyahTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BooyahTheme.maroon.withOpacity(0.2)),
                ),
                child: Column(children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: Row(children: const [
                      SizedBox(width: 28),
                      SizedBox(width: 8),
                      Expanded(child: Text('TIM', style: TextStyle(fontSize: 9, color: BooyahTheme.textMuted, letterSpacing: 0.8))),
                      SizedBox(width: 4),
                      SizedBox(width: 72, child: Text('PLACEMENT', style: TextStyle(fontSize: 8, color: BooyahTheme.textMuted), textAlign: TextAlign.center)),
                      SizedBox(width: 4),
                      SizedBox(width: 52, child: Text('KILLS', style: TextStyle(fontSize: 9, color: BooyahTheme.textMuted), textAlign: TextAlign.center)),
                      SizedBox(width: 4),
                      SizedBox(width: 44, child: Text('TOTAL', style: TextStyle(fontSize: 9, color: BooyahTheme.textMuted), textAlign: TextAlign.center)),
                    ]),
                  ),
                  const Divider(height: 1, color: Colors.white12),
                  ..._teams.map((t) => _buildScoreRow(t)),
                ]),
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: BooyahTheme.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: BooyahTheme.red.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber, color: BooyahTheme.red, size: 16),
                    const SizedBox(width: 8),
                    Text(_error!, style: const TextStyle(color: BooyahTheme.red, fontSize: 11)),
                  ]),
                ),
              ],

              const SizedBox(height: 14),

              // Live preview leaderboard
              const SectionHeader(title: 'PREVIEW LEADERBOARD'),
              Container(
                decoration: BoxDecoration(
                  color: BooyahTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BooyahTheme.maroon.withOpacity(0.2)),
                ),
                child: Column(
                  children: _sorted.asMap().entries.map((e) {
                    final rank = e.key + 1;
                    final t = e.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.04))),
                        color: rank <= 3 ? BooyahTheme.maroon.withOpacity(0.06) : null,
                      ),
                      child: Row(children: [
                        _rankBadge(rank),
                        const SizedBox(width: 10),
                        Text(t.icon, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(t.teamName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                        Text('${t.kills}K', style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted)),
                        const SizedBox(width: 12),
                        Text('${t.totalPoint} PTS',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                            color: rank == 1 ? BooyahTheme.gold : rank == 2 ? BooyahTheme.silver : rank == 3 ? BooyahTheme.bronze : BooyahTheme.textSec)),
                      ]),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: BooyahButton(
            label: 'SIMPAN HASIL & UPDATE LEADERBOARD',
            onTap: _saveResults, isLoading: _loading,
            color: const Color(0xFF1a5c1a),
          ),
        ),
      ],
    ),
  );

  Widget _buildScoreRow(TeamScoreModel t) {
    final idx = _teams.indexOf(t);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.04)))),
      child: Row(children: [
        Text(t.icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(child: Text(t.teamName,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
        const SizedBox(width: 4),
        // Placement dropdown
        SizedBox(
          width: 72,
          child: DropdownButtonFormField<int>(
            value: t.placement,
            dropdownColor: BooyahTheme.surface,
            style: const TextStyle(fontFamily: 'Orbitron', fontSize: 12, color: BooyahTheme.textPri, fontWeight: FontWeight.w700),
            isDense: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: BooyahTheme.maroon.withOpacity(0.3)),
              ),
            ),
            items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text('#${i+1}'))),
            onChanged: (v) => setState(() => _teams[idx].placement = v!),
          ),
        ),
        const SizedBox(width: 4),
        // Kills input
        SizedBox(
          width: 52,
          child: TextFormField(
            initialValue: '${t.kills}',
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Orbitron', fontSize: 13, color: BooyahTheme.textPri, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: BooyahTheme.maroon.withOpacity(0.3)),
              ),
            ),
            onChanged: (v) => setState(() => _teams[idx].kills = int.tryParse(v) ?? 0),
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
            child: Text('${t.totalPoint}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Orbitron', fontSize: 12, fontWeight: FontWeight.w800, color: BooyahTheme.gold)),
          ),
        ),
      ]),
    );
  }

  Widget _pointChip(String place, String pts) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 3),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: BooyahTheme.bg, borderRadius: BorderRadius.circular(4)),
      child: Column(children: [
        Text(place, style: const TextStyle(fontSize: 9, color: BooyahTheme.textMuted)),
        Text('+$pts', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: BooyahTheme.gold)),
      ]),
    ),
  );

  Widget _rankBadge(int rank) {
    final colors = {1: BooyahTheme.gold, 2: BooyahTheme.silver, 3: BooyahTheme.bronze};
    final color = colors[rank] ?? BooyahTheme.textMuted;
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Center(child: Text('$rank',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color))),
    );
  }
}
