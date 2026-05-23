import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../services/supabase_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> scrims = [];
  bool _loading = true;

@override
  void initState() {
    super.initState();
    _initBookingInitialData();
  }

  Future<void> _initBookingInitialData() async {
    try {
      final data = await ScrimService.getAll(status: 'open', page: 1, limit: 50);
      if (data.isNotEmpty) {
        final earliestDate = _getEarliestScrimDate(data);
        if (earliestDate != null) {
          _selectedDate = earliestDate;
        }
      }
      // Setelah mendapatkan tanggal scrim terdekat, muat data yang terfilter
      loadScrims();
    } catch (e) {
      debugPrint('Error init booking: $e');
      setState(() => _loading = false);
    }
  }

Future<void> loadScrims() async {
    try {
      setState(() => _loading = true);
      
      // 1. Ambil semua open scrim dari database
      final data = await ScrimService.getAll(status: 'open', page: 1, limit: 50);
      
      // 2. Saring data di sisi aplikasi agar HANYA menampilkan scrim yang tanggalnya cocok dengan _selectedDate
      final filteredData = data.where((scrim) {
        if (scrim['scheduled_at'] == null) return false;
        final scrimDate = DateTime.parse(scrim['scheduled_at']);
        
        return scrimDate.year == _selectedDate.year &&
               scrimDate.month == _selectedDate.month &&
               scrimDate.day == _selectedDate.day;
      }).toList();

      setState(() {
        scrims = filteredData;
      });
    } catch (e) {
      debugPrint('Error loading scrims: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  DateTime? _getEarliestScrimDate(List<Map<String, dynamic>> scrimList) {
    if (scrimList.isEmpty) return null;
    try {
      DateTime earliest = DateTime.parse(scrimList.first['scheduled_at'] ?? '');
      for (final scrim in scrimList) {
        final scheduledAt = DateTime.parse(scrim['scheduled_at'] ?? '');
        if (scheduledAt.isBefore(earliest)) {
          earliest = scheduledAt;
        }
      }
      return earliest;
    } catch (e) {
      debugPrint('Error parsing scrim dates: $e');
      return null;
    }
  }

  List<DateTime> get _weekDays {
    final start = DateTime.now();
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  bool _isFull(Map s)       => (s['slot_filled'] as int? ?? 0) >= (s['slot_total'] as int? ?? 1);
  bool _isAlmost(Map s)     => !_isFull(s) && ((s['slot_filled'] as int? ?? 0) / (s['slot_total'] as int? ?? 1)) >= 0.7;
  Color _slotColor(Map s)   => _isFull(s) ? BooyahTheme.red : _isAlmost(s) ? BooyahTheme.yellow : BooyahTheme.green;
  String _slotLabel(Map s)  => _isFull(s) ? 'PENUH' : '${s['slot_filled']}/${s['slot_total']} TIM';

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(title: const Text('BOOKING SCRIM')),
    body: Column(children: [
      // Calendar strip
      Container(
        color: BooyahTheme.surface,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(_fmtMonth(_selectedDate), style: const TextStyle(fontSize: 10, color: BooyahTheme.maroonB, fontWeight: FontWeight.w700, letterSpacing: 2)),
          ),
          SizedBox(
            height: 76,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _weekDays.length,
              itemBuilder: (_, i) {
                final d = _weekDays[i];
                final active = d.day == _selectedDate.day && d.month == _selectedDate.month;
                final dayNames = ['Sen','Sel','Rab','Kam','Jum','Sab','Min'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = d);
                    loadScrims();
                  },
                  child: Container(
                    width: 58,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: active ? BooyahTheme.maroon : BooyahTheme.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: active ? BooyahTheme.maroonB : BooyahTheme.maroon.withValues(alpha: 0.2)),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(dayNames[d.weekday - 1], style: TextStyle(fontSize: 9, color: active ? Colors.white : BooyahTheme.textMuted, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text('${d.day}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: active ? BooyahTheme.gold : BooyahTheme.textPri)),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),

      // Legend
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(children: [
          const Text('KETERANGAN:', style: TextStyle(fontSize: 10, color: BooyahTheme.textMuted)),
          const SizedBox(width: 10),
          _legend(BooyahTheme.green, 'Tersedia'),
          const SizedBox(width: 10),
          _legend(BooyahTheme.yellow, 'Hampir Penuh'),
          const SizedBox(width: 10),
          _legend(BooyahTheme.red, 'Penuh'),
        ]),
      ),
      const Divider(height: 1, color: Colors.white12),

      // Scrim list
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFB22222)))
            : scrims.isEmpty
            ? const Center(child: Text('Tidak ada jadwal tersedia.', style: TextStyle(color: BooyahTheme.textMuted)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('PILIH SCRIM TERLEBIH DAHULU', style: TextStyle(fontSize: 11, color: BooyahTheme.textMuted, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: scrims.length,
                    itemBuilder: (_, idx) {
                      final scrim = scrims[idx];
                      final isFull = _isFull(scrim);
                      final isPremium = scrim['is_premium'] as bool? ?? false;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [BooyahTheme.maroonD, BooyahTheme.bg],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header dengan badge premium & mode
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    if (isPremium) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: BooyahTheme.gold.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: BooyahTheme.gold),
                                        ),
                                        child: const Row(children: [
                                          Icon(
                                            Icons.star,
                                            size: 10,
                                            color: BooyahTheme.gold,
                                          ),
                                          SizedBox(width: 4),
                                          Text('PREMIUM', style: TextStyle(fontSize: 8, color: BooyahTheme.gold, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                        ]),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: BooyahTheme.green.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(scrim['mode'] ?? 'N/A', style: const TextStyle(fontSize: 8, color: BooyahTheme.green, fontWeight: FontWeight.w700)),
                                    ),
                                  ]),
                                  Icon(Icons.sports_esports, color: _slotColor(scrim), size: 18),
                                ],
                              ),
                            ),

                            // Judul scrim
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                scrim['title'] ?? 'Untitled Scrim',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: BooyahTheme.textPri, letterSpacing: 0.5),
                              ),
                            ),

                            // Admin/organizer
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: Text(
                                scrim['admin_profiles']?['display_name'] ?? 'Unknown Admin',
                                style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted),
                              ),
                            ),

                            const Divider(height: 12, color: Colors.white12),

                            // Info: date, time, region
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 12, color: BooyahTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text(_formatDate(scrim['scheduled_at'] ?? ''), style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.favorite, size: 12, color: BooyahTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text(_formatTime(scrim['scheduled_at'] ?? ''), style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted)),
                                    ],
                                  ),
                                  Row(
                                    children: [ 
                                      const Icon(Icons.flag, size: 12, color: BooyahTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        (scrim['mode'] as String? ?? '').toLowerCase().contains('clash_squad') 
                                            ? 'CS' 
                                            : 'BR', 
                                        style: const TextStyle(fontSize: 10, color: BooyahTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const Divider(height: 1, color: Colors.white12),

                            // Stats boxes
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _statBox('SLOT', _slotLabel(scrim), _slotColor(scrim)),
                                  _statBox('BIAYA', 'Rp${scrim['fee'] ?? 0}', BooyahTheme.gold),
                                  _statBox('HADIAH', 'Rp${scrim['prize_pool'] ?? 0}', BooyahTheme.green),
                                ],
                              ),
                            ),

                            // Button
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isFull ? null : () {
                                    Navigator.pushNamed(ctx, AppRoutes.detailScrim, arguments: scrim['id']);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFull ? BooyahTheme.surface : BooyahTheme.maroon,
                                    disabledBackgroundColor: BooyahTheme.surface,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text(
                                    isFull ? 'SLOT PENUH' : 'DAFTAR SEKARANG',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isFull ? BooyahTheme.red : Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ]),
              ),
      ),
    ]),
  );

  String _fmtMonth(DateTime d) {
    const months = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
    return '${months[d.month - 1]} ${d.year}';
  }

  Widget _legend(Color c, String label) => Row(children: [
    Container(width: 7, height: 7, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.w700)),
  ]);

  Widget _statBox(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: BooyahTheme.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: BooyahTheme.textMuted, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    ),
  );
}