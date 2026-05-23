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
          // =========================
          // BANTUAN
          // =========================

          _SectionTitle('BANTUAN'),

          _FaqTile(
            question: 'Cara Daftar Akun',
            answer:
                'Buka halaman registrasi lalu isi nama, email, password, dan data lainnya. Setelah data valid, akun akan otomatis tersimpan dan dapat digunakan untuk login.',
          ),

          _FaqTile(
            question: 'Cara Booking Slot Scrim',
            answer:
                'Pilih jadwal scrim yang tersedia pada halaman beranda atau kalender scrim, lalu isi formulir pendaftaran tim dan lakukan booking slot.',
          ),

          _FaqTile(
            question: 'Cara Upload Bukti Pembayaran',
            answer:
                'Setelah memilih metode pembayaran seperti QRIS atau transfer bank, upload bukti pembayaran melalui halaman pembayaran agar admin dapat melakukan verifikasi.',
          ),

          _FaqTile(
            question: 'Cara Klaim Hadiah',
            answer:
                'Masuk ke menu Klaim Hadiah lalu isi data rekening bank atau e-wallet dengan benar. Setelah diverifikasi, hadiah akan diproses oleh platform.',
          ),

          _FaqTile(
            question: 'Cara Melihat Room ID',
            answer:
                'Room ID akan dikirim otomatis melalui sistem notifikasi setelah pembayaran diverifikasi oleh admin scrim.',
          ),

          SizedBox(height: 24),

          // =========================
          // FAQ
          // =========================

          _SectionTitle('FAQ'),

          _FaqTile(
            question: 'Apa itu BooyahHub?',
            answer:
                'BooyahHub adalah platform manajemen scrim dan turnamen game yang mendukung pendaftaran scrim, pembayaran, leaderboard, distribusi hadiah, dan monitoring pertandingan.',
          ),

          _FaqTile(
            question: 'Kenapa status pembayaran masih menunggu?',
            answer:
                'Pembayaran masih dalam proses pengecekan admin. Pastikan bukti transfer yang diupload jelas dan sesuai nominal.',
          ),

          _FaqTile(
            question: 'Apakah slot scrim bisa penuh?',
            answer:
                'Ya. Sistem akan otomatis menutup slot scrim jika kuota tim sudah terpenuhi.',
          ),

          _FaqTile(
            question: 'Bagaimana jika pembayaran ditolak?',
            answer:
                'Jika pembayaran tidak valid, status pendaftaran akan ditolak dan slot akan dibuka kembali oleh sistem.',
          ),

          _FaqTile(
            question: 'Apakah leaderboard dihitung otomatis?',
            answer:
                'Ya. Sistem akan menghitung poin pertandingan dan memperbarui leaderboard secara otomatis setelah admin menginput hasil pertandingan.',
          ),

          _FaqTile(
            question: 'Bagaimana cara melihat riwayat scrim?',
            answer:
                'Buka menu Riwayat untuk melihat daftar scrim yang pernah diikuti beserta status pertandingan.',
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: BooyahTheme.maroonB,
        ),
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
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}