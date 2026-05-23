import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../shared/widgets/scrim_card.dart';
import '../../shared/models/scrim_model.dart';
import '../../services/supabase_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  List<Map<String, dynamic>> _allRawScrims = [];
  List<ScrimModel> _filteredScrims = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInitialScrims();
    // Berikan fokus otomatis ke search bar saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // Mengambil data awal dari Supabase
  Future<void> _fetchInitialScrims() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ScrimService.getAll(status: 'open');
      _allRawScrims = data;
      _applyFilter(''); // Inisialisasi daftar kosong atau tampilkan semua di awal
    } on PostgrestException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // Melakukan filter lokal berdasarkan teks yang diketik pengguna
  void _applyFilter(String query) {
    final parsedScrims = _allRawScrims.map((s) => ScrimModel(
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

    setState(() {
      if (query.isEmpty) {
        // Jika kosong, kamu bisa memilih menampilkan semua scrim atau dikosongkan
        _filteredScrims = parsedScrims; 
      } else {
        _filteredScrims = parsedScrims
            .where((scrim) => scrim.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
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
      backgroundColor: BooyahTheme.bg,
      appBar: AppBar(
        backgroundColor: BooyahTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // Search Bar diletakkan di dalam Judul AppBar agar responsif
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: BooyahTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            onChanged: _applyFilter,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ketik nama scrim...',
              hintStyle: const TextStyle(color: BooyahTheme.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: BooyahTheme.textMuted, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: BooyahTheme.textMuted, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilter('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: BooyahTheme.maroonB),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: const TextStyle(color: Color(0xFFFF1744)), textAlign: TextAlign.center),
        ),
      );
    }

    if (_filteredScrims.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined, size: 64, color: BooyahTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'Scrim tidak ditemukan',
              style: TextStyle(color: BooyahTheme.textMuted, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _filteredScrims.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: ScrimCard(
          scrim: _filteredScrims[i],
          onTap: () {
            Navigator.pushNamed(
              ctx, 
              '/detail', arguments: _filteredScrims[i],
            );
          },
        ),
      ),
    );
  }
} 