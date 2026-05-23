import 'package:flutter/material.dart';
import '../../core/theme.dart';

class TentangAplikasiScreen extends StatelessWidget {
  const TentangAplikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TENTANG APLIKASI'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BooyahTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BooyahTheme.maroon.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Icon(
                Icons.sports_esports,
                size: 70,
                color: BooyahTheme.maroonB,
              ),

              SizedBox(height: 16),

              Text(
                'BOOYAHHUB',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),

              SizedBox(height: 14),

              Text(
                'BooyahHub adalah aplikasi manajemen scrim dan turnamen esports yang dirancang untuk membantu peserta, admin scrim, dan platform dalam mengelola pertandingan secara lebih terstruktur, cepat, dan efisien.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: BooyahTheme.textMuted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),

              SizedBox(height: 24),

              Divider(),

              SizedBox(height: 18),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Fitur Utama',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: BooyahTheme.maroonB,
                  ),
                ),
              ),

              SizedBox(height: 12),

              _FeatureItem('Pendaftaran scrim online'),
              _FeatureItem('Booking slot scrim real-time'),
              _FeatureItem('Upload bukti pembayaran'),
              _FeatureItem('Distribusi Room ID otomatis'),
              _FeatureItem('Leaderboard pertandingan'),
              _FeatureItem('Sistem klaim hadiah'),
              _FeatureItem('Notifikasi dan pengumuman'),
              _FeatureItem('Riwayat scrim peserta'),

              SizedBox(height: 24),

              Divider(),

              SizedBox(height: 18),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tujuan Aplikasi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: BooyahTheme.maroonB,
                  ),
                ),
              ),

              SizedBox(height: 12),

              Text(
                'BooyahHub dibuat untuk mengatasi proses manajemen scrim yang masih manual, seperti pencatatan peserta, pembagian jadwal, verifikasi pembayaran, hingga distribusi hasil pertandingan dan hadiah.',
                textAlign: TextAlign.justify,
                style: TextStyle(
                  color: BooyahTheme.textMuted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),

              SizedBox(height: 24),

              Divider(),

              SizedBox(height: 18),

              Text(
                'Versi Aplikasi',
                style: TextStyle(
                  color: BooyahTheme.textMuted,
                  fontSize: 11,
                ),
              ),

              SizedBox(height: 4),

              Text(
                'v1.0.0',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: BooyahTheme.maroonB,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: BooyahTheme.textSec,
              ),
            ),
          ),
        ],
      ),
    );
  }
}