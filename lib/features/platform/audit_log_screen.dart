import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  // Instance Supabase Client untuk koneksi ke database
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs(); // Jalankan penarikan data saat halaman pertama kali dibuka
  }

  // FUNGSI UTAMA: Mengambil data dari tabel 'audit_logs' di Supabase
  Future<void> _fetchAuditLogs() async {
    try {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });

      // Melakukan query ke tabel 'audit_logs'
      final List<dynamic> response = await _supabase
          .from('audit_logs')
          .select('*') // Mengambil semua kolom
          .order('created_at', ascending: false); // Mengurutkan dari yang paling baru

      setState(() {
        // Konversi hasil response menjadi List<Map> yang aman bagi Flutter
        _logs = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat log: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUDIT LOGS SISTEM'),
        actions: [
          // Tombol Refresh untuk menarik data ulang secara manual
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAuditLogs,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: BooyahTheme.maroonGlow))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: BooyahTheme.red)))
              : _logs.isEmpty
                  ? const Center(child: Text('Belum ada riwayat aktivitas sistem.', style: TextStyle(color: BooyahTheme.textMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        
                        // Menangani jika nilai kolom null di database agar aplikasi tidak crash
                        final String rawRole = log['actor_role'] as String? ?? 'System';
                        final String actorRole = rawRole.isNotEmpty 
                            ? '${rawRole[0].toUpperCase()}${rawRole.substring(1)}' 
                            : 'System';
                        final String action = log['action'] as String? ?? 'UNKNOWN_ACTION';
                        final String description = log['description'] as String? ?? '-';
                        // 1. Ambil data mentah string dari database
                        final String rawCreatedAt = log['created_at'] as String? ?? '';
                        String formattedDate = '-';

                        if (rawCreatedAt.isNotEmpty) {
                          try {
                            // 2. Ubah string Supabase menjadi objek DateTime Flutter (Otomatis konversi ke waktu lokal HP)
                            final DateTime dateTime = DateTime.parse(rawCreatedAt).toLocal();
                            
                            // 3. Buat daftar nama bulan Indonesia
                            const List<String> months = [
                              'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 
                              'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
                            ];
                            
                            // 4. Susun formatnya: DD MMMM YYYY, HH:mm
                            final String day = dateTime.day.toString().padLeft(2, '0');
                            final String month = months[dateTime.month - 1];
                            final String year = dateTime.year.toString();
                            final String hour = dateTime.hour.toString().padLeft(2, '0');
                            final String minute = dateTime.minute.toString().padLeft(2, '0');
                            
                            formattedDate = '$day $month $year, $hour:$minute';
                          } catch (e) {
                            // Jika format database error, fallback ke string mentah yang dipotong aman
                            formattedDate = rawCreatedAt.length > 10 ? rawCreatedAt.substring(0, 10) : rawCreatedAt;
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: BooyahTheme.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // 1. Aktor Riil dari DB
                                  Text(
                                    'Aktor: $actorRole', // Mengambil data dari kolom actor_role (misal: Admin, Platform, atau Peserta)
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: BooyahTheme.maroonGlow, fontSize: 12),
                                  ),
                                  // 2. Waktu Kejadian Riil dari DB
                                  Text(
                                    formattedDate, 
                                    style: const TextStyle(color: BooyahTheme.textMuted, fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // 3. Jenis Aksi/Kode Event Internal
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: BooyahTheme.surface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  action.replaceAll('_', ' ').toLowerCase().split(' ').map((word) {
                                    if (word.isEmpty) return '';
                                    return '${word[0].toUpperCase()}${word.substring(1)}';
                                  }).join(' '),
                                  style: const TextStyle(
                                    fontFamily: 'Orbitron', 
                                    fontSize: 9, 
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white, 
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 4. Deskripsi Detail Riil dari DB
                              Text(
                                description,
                                style: const TextStyle(fontSize: 12, color: BooyahTheme.textSec),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}