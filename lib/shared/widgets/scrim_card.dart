import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../models/scrim_model.dart';

class ScrimCard extends StatelessWidget {
  final ScrimModel scrim;
  final VoidCallback? onTap;

  const ScrimCard({super.key, required this.scrim, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: BooyahTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scrim.isPremium
                ? BooyahTheme.gold.withOpacity(0.35)
                : BooyahTheme.maroon.withOpacity(0.25),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12)],
        ),
        child: Column(
          children: [
            // Banner
            _buildBanner(),
            // Body
            _buildBody(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C0000), Color(0xFF2A1000), BooyahTheme.surface],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (scrim.isPremium) _badge('★ PREMIUM',
                bg: BooyahTheme.gold, fg: Colors.black),
              if (scrim.isPremium) const SizedBox(width: 6),
              _slotBadge(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(scrim.title, style: const TextStyle(
                fontFamily: 'Orbitron', fontSize: 14,
                fontWeight: FontWeight.w700, letterSpacing: 1,
              )),
              Text('🔥 ${scrim.adminName}',
                style: const TextStyle(fontSize: 11, color: BooyahTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Info row
          Row(
            children: [
              _info(Icons.calendar_today, scrim.date),
              const SizedBox(width: 12),
              _info(Icons.access_time, scrim.time),
              const SizedBox(width: 12),
              _info(Icons.sports_esports, scrim.mode),
            ],
          ),
          const SizedBox(height: 10),

          // Stats row
          Row(
            children: [
              _statPill('SLOT', '${scrim.slotFilled}/${scrim.slotTotal}',
                color: BooyahTheme.maroonB),
              const SizedBox(width: 8),
              _statPill('BIAYA', 'Rp${_fmt(scrim.fee)}',
                color: BooyahTheme.textSec),
              const SizedBox(width: 8),
              _statPill('HADIAH', 'Rp${_fmt(scrim.prize)}',
                color: BooyahTheme.gold),
            ],
          ),
          const SizedBox(height: 10),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: scrim.isFull ? null : () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: scrim.isFull
                    ? BooyahTheme.surface : BooyahTheme.maroon,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(scrim.isFull ? 'SLOT PENUH' : 'DAFTAR SEKARANG',
                style: const TextStyle(fontSize: 12, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotBadge() {
    Color bg, fg;
    if (scrim.isFull) {
      bg = BooyahTheme.red.withOpacity(0.15);
      fg = BooyahTheme.red;
    } else if (scrim.isAlmostFull) {
      bg = BooyahTheme.yellow.withOpacity(0.15);
      fg = BooyahTheme.yellow;
    } else {
      bg = BooyahTheme.green.withOpacity(0.15);
      fg = BooyahTheme.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(3),
        border: Border.all(color: fg.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(scrim.slotStatus, style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.8)),
        ],
      ),
    );
  }

  Widget _badge(String label, {required Color bg, required Color fg}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)),
        child: Text(label, style: TextStyle(
          fontSize: 9, fontWeight: FontWeight.w800, color: fg, letterSpacing: 1)),
      );

  Widget _info(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 11, color: BooyahTheme.maroonB),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 11, color: BooyahTheme.textSec)),
    ],
  );

  Widget _statPill(String label, String val, {required Color color}) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: BooyahTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: BooyahTheme.maroon.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: BooyahTheme.textMuted)),
          Text(val, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    ),
  );

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}jt';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(0)}k';
    return n.toString();
  }
}
