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
  bool _saving = false;
  String? _error;
  late int scrimId;
  Map<String, dynamic>? _scrimData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        scrimId = args;
      } else if (args is Map) {
        scrimId = args['scrimId'] ?? 1;
      } else {
        scrimId = 1;
      }
      _loadTeams();
    });
  }

  Future<void> _loadTeams() async {
    setState(() => _loading = true);
    try {
      // 1. Fetch scrim details
      final scrim = await ScrimService.getById(scrimId.toString());
      _scrimData = scrim;

      // 2. Ambil tim yang sudah verified di scrim ini
      final data = await RegistrationService.getByScrim(scrimId);

      if (data.isEmpty) {
        setState(() => _error = 'Belum ada tim yang terdaftar untuk scrim ini');
      }

      setState(() {
        _teams = data
            .where((d) => d['status'] == 'verified' || d['status'] == 'ongoing')
            .map(
              (d) => TeamScoreModel(
                id: d['id'].toString(),
                teamName: d['team_name'] as String,
                icon: '',
                placement: 1,
                kills: 0,
              ),
            )
            .toList();
      });

      await _checkExistingResults();
    } catch (e) {
      debugPrint('Error load teams: $e');
      setState(() => _error = 'Gagal memuat data: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkExistingResults() async {
    try {
      final existingResults = await ResultService.getByScrim(scrimId);
      if (existingResults.isNotEmpty && mounted) {
        final shouldLoad = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hasil Sebelumnya Ditemukan'),
            content: Text(
              'Scrim ini sudah memiliki hasil yang tersimpan. Apakah Anda ingin memuat data yang sudah ada?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Mulai Baru'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Muat Data'),
              ),
            ],
          ),
        );

        if (shouldLoad == true && mounted) {
          setState(() {
            for (var result in existingResults) {
              final teamIndex = _teams.indexWhere(
                (t) => t.id == result['registration_id'].toString(),
              );
              if (teamIndex != -1) {
                _teams[teamIndex].placement = result['placement'] ?? 1;
                _teams[teamIndex].kills = result['kills'] ?? 0;
              }
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data hasil sebelumnya dimuat')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking existing results: $e');
    }
  }

  List<TeamScoreModel> get _sorted =>
      [..._teams]..sort((a, b) => b.totalPoint.compareTo(a.totalPoint));

  bool _validateInputs() {
    // Validasi placement harus unik dari 1 sampai jumlah tim
    final placements = <int>[];
    for (final t in _teams) {
      if (t.kills < 0) {
        setState(() => _error = 'Jumlah kills tidak boleh negatif!');
        return false;
      }
      if (t.placement < 1 || t.placement > _teams.length) {
        setState(
          () => _error = 'Placement harus antara 1 dan ${_teams.length}',
        );
        return false;
      }
      if (placements.contains(t.placement)) {
        setState(
          () => _error =
              'Placement #${t.placement} sudah digunakan oleh tim lain!',
        );
        return false;
      }
      placements.add(t.placement);
    }

    // Pastikan semua placement terisi 1 sampai jumlah tim
    placements.sort();
    for (int i = 0; i < placements.length; i++) {
      if (placements[i] != i + 1) {
        setState(
          () => _error =
              'Placement harus berurutan dari 1 sampai ${_teams.length}',
        );
        return false;
      }
    }

    setState(() => _error = null);
    return true;
  }

  void _saveResults() async {
    if (!_validateInputs()) return;

    // Konfirmasi sebelum menyimpan
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Simpan Hasil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin menyimpan hasil ini?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BooyahTheme.bg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: _sorted.take(3).map((t) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${_sorted.indexOf(t) + 1}. ${t.teamName} - ${t.totalPoint} PTS',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (_teams.length > 3)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  '...dan tim lainnya',
                  style: TextStyle(fontSize: 11),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: BooyahTheme.green),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _saving = true;
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
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
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
                Expanded(child: Text('Gagal menyimpan: ${e.toString()}')),
              ],
            ),
            backgroundColor: const Color(0xFFFF1744),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetAllInputs() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Semua Input'),
        content: const Text('Yakin ingin mereset semua input hasil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                for (var i = 0; i < _teams.length; i++) {
                  _teams[i].placement = i + 1;
                  _teams[i].kills = 0;
                }
                _error = null;
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Semua input telah direset')),
              );
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
      title: const Text('INPUT HASIL PERTANDINGAN'),
      actions: [
        if (!_loading && _teams.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadTeams,
            tooltip: 'Refresh data',
          ),
        if (!_loading && _teams.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.restart_alt, size: 20),
            onPressed: _resetAllInputs,
            tooltip: 'Reset semua input',
          ),
        Chip(
          label: const Text('ADMIN', style: TextStyle(fontSize: 9)),
          backgroundColor: BooyahTheme.yellow.withValues(alpha: 0.15),
          labelStyle: const TextStyle(
            color: BooyahTheme.yellow,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _teams.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: BooyahTheme.textMuted,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Belum ada tim terdaftar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Silakan daftarkan tim terlebih dahulu',
                  style: const TextStyle(
                    fontSize: 12,
                    color: BooyahTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadTeams,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          )
        : Column(
            children: [
              // Scrim info banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                color: BooyahTheme.surface,
                child: Row(
                  children: [
                    const Icon(
                      Icons.sports_esports,
                      size: 16,
                      color: BooyahTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_scrimData?['title'] ?? 'BOOYAH CUP'} · ${_scrimData?['scheduled_at']?.toString().split(' ')[0] ?? 'Tanggal belum diatur'} · ${_teams.length} Tim',
                        style: const TextStyle(
                          fontSize: 11,
                          color: BooyahTheme.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                      _buildPointSystemCard(),
                      const SizedBox(height: 14),

                      // Input per tim
                      const SectionHeader(title: 'INPUT HASIL TIM'),
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
                            _buildTableHeader(),
                            const Divider(height: 1, color: Colors.white12),
                            ..._teams.asMap().entries.map(
                              (entry) => _buildScoreRow(entry.value, entry.key),
                            ),
                          ],
                        ),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        _buildErrorWidget(),
                      ],

                      const SizedBox(height: 14),

                      // Live preview leaderboard
                      const SectionHeader(title: 'PREVIEW LEADERBOARD'),
                      _buildLeaderboardPreview(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Tombol simpan
              _buildSaveButton(),
            ],
          ),
  );

  Widget _buildPointSystemCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BooyahTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.25)),
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
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: const [
          SizedBox(width: 24),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'NAMA TIM',
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
              'PLACEMENT',
              style: TextStyle(fontSize: 8, color: BooyahTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 4),
          SizedBox(
            width: 52,
            child: Text(
              'KILLS',
              style: TextStyle(fontSize: 9, color: BooyahTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 4),
          SizedBox(
            width: 44,
            child: Text(
              'TOTAL',
              style: TextStyle(fontSize: 9, color: BooyahTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(TeamScoreModel t, int idx) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            alignment: Alignment.center,
            child: Text(
              '${idx + 1}',
              style: const TextStyle(
                fontSize: 11,
                color: BooyahTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t.teamName,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          // Placement dropdown
          SizedBox(
            width: 72,
            child: DropdownButtonFormField<int>(
              value: t.placement,
              dropdownColor: BooyahTheme.surface,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 12,
                color: BooyahTheme.textPri,
                fontWeight: FontWeight.w700,
              ),
              isDense: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(
                    color: BooyahTheme.maroon.withValues(alpha: 0.3),
                  ),
                ),
              ),
              items: List.generate(
                _teams.length,
                (i) => DropdownMenuItem(value: i + 1, child: Text('#${i + 1}')),
              ),
              onChanged: (v) {
                setState(() {
                  _teams[idx].placement = v!;
                  _validateInputs();
                });
              },
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
                setState(() {
                  _teams[idx].kills = int.tryParse(v) ?? 0;
                  _validateInputs();
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
        ],
      ),
    );
  }

  Widget _buildLeaderboardPreview() {
    if (_sorted.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: BooyahTheme.card,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('Belum ada data untuk ditampilkan')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: BooyahTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: _sorted.asMap().entries.map((e) {
          final rank = e.key + 1;
          final t = e.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
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
                    overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: BooyahTheme.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: BooyahTheme.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: BooyahTheme.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: BooyahTheme.red, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: BooyahButton(
        label: _saving ? 'MENYIMPAN...' : 'SIMPAN HASIL & UPDATE LEADERBOARD',
        onTap: _saving ? null : _saveResults,
        isLoading: _saving,
        color: BooyahTheme.green,
      ),
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
