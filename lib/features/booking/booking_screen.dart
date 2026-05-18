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
  String? _selectedSlot;
  List<Map<String, dynamic>> _slots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    try {
      setState(() => _loading = true);
      final data = await BookingService.getAvailableSlots(_selectedDate);
      setState(() => _slots = data);
    } catch (e) {
      debugPrint('Error loading slots: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<DateTime> get _weekDays {
    final start = DateTime.now();
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  bool _isFull(Map s)       => (s['filled'] as int? ?? 0) >= (s['total'] as int? ?? 1);
  bool _isAlmost(Map s)     => !_isFull(s) && ((s['filled'] as int? ?? 0) / (s['total'] as int? ?? 1)) >= 0.7;
  Color _slotColor(Map s)   => _isFull(s) ? BooyahTheme.red : _isAlmost(s) ? BooyahTheme.yellow : BooyahTheme.green;
  String _slotLabel(Map s)  => _isFull(s) ? 'PENUH' : '${s['filled']}/${s['total']} TIM';

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
                    _selectedSlot = null;
                    _loadSlots();
                  },
                  child: Container(
                    width: 58,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: active ? BooyahTheme.maroon : BooyahTheme.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: active ? BooyahTheme.maroonB : BooyahTheme.maroon.withOpacity(0.2)),
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
          _legend(BooyahTheme.green, 'TERSEDIA'),
          const SizedBox(width: 10),
          _legend(BooyahTheme.yellow, 'HAMPIR PENUH'),
          const SizedBox(width: 10),
          _legend(BooyahTheme.red, 'PENUH'),
        ]),
      ),
      const Divider(height: 1, color: Colors.white12),

      // Slot grid
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFB22222)))
            : _slots.isEmpty
            ? const Center(child: Text('Tidak ada jadwal di tanggal ini.', style: TextStyle(color: BooyahTheme.textMuted)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('PILIH JAM SCRIM', style: TextStyle(fontSize: 11, color: BooyahTheme.textMuted, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: 2.8),
                    itemCount: _slots.length,
                    itemBuilder: (_, i) {
                      final slot = _slots[i];
                      final selected = _selectedSlot == slot['time'];
                      final isFull = _isFull(slot);
                      return GestureDetector(
                        onTap: isFull ? null : () => setState(() => _selectedSlot = slot['time']),
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected ? _slotColor(slot).withOpacity(0.25) : BooyahTheme.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected ? _slotColor(slot) : BooyahTheme.maroon.withOpacity(0.2),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(slot['time'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _slotColor(slot))),
                            Text(_slotLabel(slot), style: TextStyle(fontSize: 10, color: _slotColor(slot))),
                          ]),
                        ),
                      );
                    },
                  ),
                ]),
              ),
      ),

      // Footer
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BooyahTheme.surface,
          border: Border(top: BorderSide(color: BooyahTheme.maroon.withOpacity(0.3))),
        ),
        child: Column(children: [
          if (_selectedSlot != null) ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('SLOT DIPILIH', style: TextStyle(fontSize: 11, color: BooyahTheme.textMuted)),
                Text('$_selectedSlot WIB', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: BooyahTheme.maroonB)),
              ]),
              Text('Rp${_slots.isNotEmpty ? _slots.first['fee'] ?? 25000 : 25000}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: BooyahTheme.gold)),
            ]),
            const SizedBox(height: 10),
          ],
          ElevatedButton(
            onPressed: _selectedSlot == null ? null : () =>
                Navigator.pushNamed(ctx, AppRoutes.detailScrim),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedSlot == null ? BooyahTheme.surface : BooyahTheme.maroon,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(_selectedSlot == null ? 'PILIH SLOT TERLEBIH DAHULU' : 'LANJUT KE DETAIL SCRIM →'),
          ),
        ]),
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
}
