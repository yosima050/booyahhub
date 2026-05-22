import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../shared/widgets/scrim_card.dart';
import '../../shared/models/scrim_model.dart';
import '../../services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'SEMUA';
  final List<String> _filters = ['SEMUA', 'PREMIUM', 'BATTLE ROYALE', 'CLASH SQUAD'];
  
  List<Map<String, dynamic>> _rawScrims = [];
  bool _loading = true;
  String? _error;

  RealtimeChannel? _scrimsSubscription;

  @override
  void initState() {
    super.initState();
    _loadScrims();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    if (_scrimsSubscription != null) {
      Supabase.instance.client.removeChannel(_scrimsSubscription!);
    }
    super.dispose();
  }

  void _subscribeRealtime() {
    try {
      _scrimsSubscription = Supabase.instance.client
          .channel('public:scrims')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'scrims',
            callback: (payload) {
              if (mounted) {
                _loadScrims(silent: true);
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Realtime subscription error: $e');
    }
  }

  Future<void> _loadScrims({bool silent = false}) async {
    if (!silent) {
      setState(() { _loading = true; _error = null; });
    }
    try {
      final data = await ScrimService.getAll(status: 'open');
      if (mounted) {
        setState(() {
          _rawScrims = data;
          _error = null;
        });
      }
    } on PostgrestException catch (e) {
      if (mounted && !silent) {
        setState(() => _error = e.message);
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _loading = false);
      }
    }
  }

  List<ScrimModel> get _scrims {
    Iterable<Map<String, dynamic>> filtered = _rawScrims;

    // Filter by category/mode
    if (_activeFilter != 'SEMUA') {
      if (_activeFilter == 'PREMIUM') {
        filtered = filtered.where((s) => s['is_premium'] == true);
      } else {
        filtered = filtered.where((s) {
          final m = (s['mode'] as String? ?? '').toUpperCase();
          return m == _activeFilter;
        });
      }
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        final title = (s['title'] as String? ?? '').toLowerCase();
        final adminName = (s['admin_profiles']?['display_name'] as String? ?? '').toLowerCase();
        return title.contains(q) || adminName.contains(q);
      });
    }

    return filtered.map((s) => ScrimModel(
      id:          s['id'].toString(),
      title:       s['title'] as String,
      adminName:   (s['admin_profiles']?['display_name'] ?? '') as String,
      date:        _fmtDate(s['scheduled_at'] as String),
      time:        _fmtTime(s['scheduled_at'] as String),
      mode:        s['mode'] as String,
      slotFilled:  s['slot_filled'] as int,
      slotTotal:   s['slot_total'] as int,
      fee:         s['fee'] as int,
      prize:       s['prize_pool'] as int,
      isPremium:   s['is_premium'] as bool? ?? false,
    )).toList();
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: BooyahTheme.maroonB,
        backgroundColor: BooyahTheme.card,
        onRefresh: () => _loadScrims(silent: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          // ── Hero Header ──
          SliverToBoxAdapter(
            child: _buildHero(),
          ),

          // ── Quick Stats ──
          SliverToBoxAdapter(
            child: _buildQuickStats(),
          ),

          // ── Search Bar ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: GestureDetector(
                onTap: () {}, // TODO: navigate to search
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: BooyahTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: BooyahTheme.textMuted,
                      size: 18,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Cari scrim...',
                          hintStyle: TextStyle(
                            color: BooyahTheme.textMuted,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    PopupMenuButton<String>(
                      onSelected: (value) {
                        setState(() {
                          _activeFilter = value;
                        });
                      },
                      color: BooyahTheme.surface,
                      itemBuilder: (context) => _filters.map((filter) {
                        return PopupMenuItem<String>(
                          value: filter,
                          child: Text(
                            filter,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),

                      child: const _FilterChipSmall(label: 'FILTER'),
                    ),
                  ],
                  ),
                ),
              ),
            ),
          ),

          // ── Filter Chips ──
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  final active = _activeFilter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _activeFilter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? BooyahTheme.maroon : BooyahTheme.surface,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: active ? BooyahTheme.maroon : BooyahTheme.maroon.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(f, style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: active ? Colors.white : BooyahTheme.textMuted,
                        letterSpacing: 0.8,
                      )),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Section Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 3, height: 18,
                    decoration: BoxDecoration(
                      color: BooyahTheme.maroonB,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [BoxShadow(color: BooyahTheme.maroonB, blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('SCRIM TERSEDIA', style: TextStyle(
                    fontFamily: 'Rajdhani', fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
                  const Spacer(),
                  Text('LIHAT SEMUA →', style: TextStyle(
                    fontSize: 12, color: BooyahTheme.maroonB, fontWeight: FontWeight.w600,
                  )),
                ],
              ),
            ),
          ),

          // ── Scrim List ──
          _buildScrimList(),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      ),
    );
  }

  Widget _buildHero() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6B0000), Color(0xFF2A0000), BooyahTheme.bg],
          begin: Alignment.topLeft, end: Alignment.bottomCenter,
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topbar
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: BooyahTheme.maroon,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/images/logo.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text('🎮', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('BooyahHub', style: TextStyle(
                fontFamily: 'Orbitron', fontSize: 14, fontWeight: FontWeight.w700)),
              const Spacer(),
              Stack(
                children: [
                  InkWell(
                    onTap: () {
                      // TODO: buka halaman notifikasi
                      Navigator.pushNamed(context, '/notification');
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: BooyahTheme.maroon.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: BooyahTheme.textPri,
                        size: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6, top: 6,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: BooyahTheme.maroonGlow, shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Live badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: BooyahTheme.maroon,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row (
              mainAxisSize: MainAxisSize.min,
              children: [
                const _LiveDot(),
                const SizedBox(width: 6),
                Text(
                  _loading 
                      ? 'LIVE · MEMUAT...' 
                      : 'LIVE · ${_rawScrims.length} SCRIM AKTIF', 
                  style: const TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.w700, 
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Hero title
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Orbitron', fontSize: 26,
                fontWeight: FontWeight.w900, letterSpacing: 2, height: 1.1,
              ),
              children: [
                TextSpan(text: 'TEMUKAN\n'),
                TextSpan(text: 'SCRIM', style: TextStyle(color: BooyahTheme.maroonB)),
                TextSpan(text: '\nTERBAIK'),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildScrimList() {
    if (_loading) {
      return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFB22222))),
      ),
    );
    }
    if (_error != null) {
      return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(_error!, style: const TextStyle(color: Color(0xFFFF1744))),
        ),
      ),
    );
    }
    if (_scrims.isEmpty) {
      return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('Belum ada scrim tersedia.',
          style: TextStyle(color: Color(0xFF888888)))),
      ),
    );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ScrimCard(
            scrim: _scrims[i],
            onTap: () => Navigator.pushNamed(ctx, AppRoutes.detailScrim,
                arguments: _scrims[i]),
          ),
        ),
        childCount: _scrims.length,
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Transform.translate(
        offset: const Offset(0, 6),
        child: Row(
          children: [
            _StatBox(icon: Icons.flag, value: '192M+', label: 'GAMER ID'),
            const SizedBox(width: 8),
            _StatBox(icon: Icons.sports_esports, value: '30M+', label: 'PEMAIN AKTIF'),
            const SizedBox(width: 8),
            _StatBox(icon: Icons.emoji_events, value: '618K+', label: 'REKOR PESERTA'),
          ],
        ),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  late final Animation<double> _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7, height: 7,
        decoration: const BoxDecoration(color: BooyahTheme.red, shape: BoxShape.circle),
      ),
    );
  }
}

class _FilterChipSmall extends StatelessWidget {
  final String label;
  const _FilterChipSmall({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: BooyahTheme.maroon.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label, style: const TextStyle(
      fontSize: 10, color: BooyahTheme.maroonB, fontWeight: FontWeight.w700, letterSpacing: 1)),
  );
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _StatBox({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: BooyahTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 18,
            color: BooyahTheme.maroonB,
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w800, color: BooyahTheme.maroonB)),
          Text(label, style: const TextStyle(
            fontSize: 8, color: BooyahTheme.textMuted, letterSpacing: 0.3)),
        ],
      ),
    ),
  );
}
