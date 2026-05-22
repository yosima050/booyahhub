import 'package:flutter/material.dart';
import '../../core/theme.dart';

class BantuanFaqScreen extends StatelessWidget {
  const BantuanFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BANTUAN & FAQ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _FaqTile(
            question: 'Bagaimana cara mengikuti scrim?',
            answer:
                'Masuk ke halaman scrim lalu pilih turnamen yang tersedia dan lakukan pendaftaran.',
          ),
          _FaqTile(
            question: 'Bagaimana cara klaim hadiah?',
            answer:
                'Hadiah dapat diklaim melalui menu Klaim Hadiah setelah pertandingan selesai.',
          ),
          _FaqTile(
            question: 'Kenapa pembayaran belum terverifikasi?',
            answer:
                'Verifikasi pembayaran biasanya membutuhkan waktu beberapa menit.',
          ),
          _FaqTile(
            question: 'Bagaimana cara mengganti foto profil?',
            answer:
                'Tekan foto profil pada halaman profil lalu pilih gambar dari perangkat.',
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: BooyahTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BooyahTheme.maroon.withValues(alpha: 0.2),
        ),
      ),
      child: ExpansionTile(
        iconColor: BooyahTheme.maroonB,
        collapsedIconColor: BooyahTheme.textMuted,
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(
                color: BooyahTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}