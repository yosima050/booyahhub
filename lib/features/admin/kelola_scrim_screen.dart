import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../admin/data_pendaftar_screen.dart';
import '../admin/verifikasi_pembayaran_screen.dart';
import '../admin/room_id_screen.dart';
import '../admin/input_hasil_screen.dart';
import '../admin/kirim_pengumuman_screen.dart';
import '../admin/laporan_scrim_screen.dart';
import '../admin/kelola_room_info_screen.dart';

class KelolaScrimScreen extends StatelessWidget {
  final Map<String, dynamic> scrim;

  const KelolaScrimScreen({super.key, required this.scrim});

  @override
  Widget build(BuildContext context) {
    final int scrimId = scrim['id'] ?? 1;

    final menus = [
      ('Data Pendaftar', Icons.groups_rounded, const DataPendaftarScreen()),
      (
        'Verifikasi Pembayaran',
        Icons.verified_user_rounded,
        const VerifikasiPembayaranScreen(),
      ),
      ('Input Room ID', Icons.vpn_key_rounded, const RoomIdScreen()),
      (
        'Input Hasil Pertandingan', // MENU 1: Input Hasil
        Icons.emoji_events_rounded,
        const InputHasilScreen(),
      ),
      (
        'Kelola Room & Info Match', // MENU 2: Kelola Room & Info Match
        Icons.meeting_room_rounded,
        const KelolaRoomInfoScreen(),
      ),
      (
        'Kirim Pengumuman',
        Icons.campaign_rounded,
        const KirimPengumumanScreen(),
      ),
      ('Laporan Scrim', Icons.bar_chart_rounded, const LaporanScrimScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('KELOLA SCRIM'),
        actions: [
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER SCRIM
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5C0000), Color(0xFF1A0000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: BooyahTheme.maroon.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.sports_esports,
                      color: BooyahTheme.yellow,
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scrim['title'] ?? 'BOOYAH SCRIM',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${scrim['scheduled_at'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'MENU ADMIN',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                color: BooyahTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: menus.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (_, i) {
                final item = menus[i];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => item.$3,
                        settings: RouteSettings(arguments: scrimId),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: BooyahTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: BooyahTheme.maroon.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: BooyahTheme.maroon.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            item.$2,
                            color: BooyahTheme.yellow,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.$1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
