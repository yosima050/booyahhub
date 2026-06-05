import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/booyah_widgets.dart';

class FormTimScreen extends StatefulWidget {
  const FormTimScreen({super.key});

  @override
  State<FormTimScreen> createState() => _FormTimScreenState();
}

class _FormTimScreenState extends State<FormTimScreen> {
  final _namaCtrl    = TextEditingController();
  final _captainCtrl = TextEditingController();
  final _hpCtrl      = TextEditingController();
  final List<TextEditingController> _memberCtrls = [TextEditingController()];

  String? _hpError;
  String? _captainError;
  final List<String?> _memberErrors = [null];

  ScrimModel? _scrim;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ScrimModel && _scrim == null) {
      _scrim = args;
    }
  }

  void _addMember() {
    setState(() {
      _memberCtrls.add(TextEditingController());
      _memberErrors.add(null); 
    });
  }

  void _removeMember(int idx) {
    setState(() {
      _memberCtrls.removeAt(idx);
      _memberErrors.removeAt(idx); 
    });
  }

  void _next() {
    if (_namaCtrl.text.isEmpty || _captainCtrl.text.isEmpty || _hpCtrl.text.isEmpty) {
      _showSnackBar('Nama tim, ID Captain, dan HP wajib diisi!', BooyahTheme.red);
      return;
    }

    if (_hpError != null || _captainError != null || _memberErrors.any((e) => e != null)) {
      _showSnackBar('Harap perbaiki data yang salah sebelum melanjutkan!', BooyahTheme.red);
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.pembayaran,
      arguments: {
        'scrim': _scrim,
        'team_name': _namaCtrl.text.trim(),
        'captain_ff_id': _captainCtrl.text.trim(),
        'phone': _hpCtrl.text.trim(),
        'members': _memberCtrls
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      },
    );
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: bgColor,
      ),
    );
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _captainCtrl.dispose();
    _hpCtrl.dispose();
    for (final c in _memberCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
      title: const Text('DAFTAR TIM'),
      actions: [
        const Padding(
          padding: EdgeInsets.only(right: 14),
          child: Center(
            child: Text(
              '1 / 2', 
              style: TextStyle(fontSize: 12, color: BooyahTheme.textMuted),
            ),
          ),
        )
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          const SectionHeader(title: 'DATA TIM'),
          const SizedBox(height: 16),
          
          // --- 1. INPUT NAMA TIM ---
          const Text(
            'NAMA TIM', 
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BooyahTheme.textMuted, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _namaCtrl, 
            style: const TextStyle(color: BooyahTheme.textPri),
            decoration: const InputDecoration(
              hintText: 'cth: FIRE WOLVES',
              prefixIcon: Icon(Icons.group, color: BooyahTheme.maroonB, size: 18),
            ),
          ),
          const SizedBox(height: 16),
          
          // --- 2. INPUT ID CAPTAIN (VALIDASI 8-12 DIGIT ANGKA) ---
          const Text(
            'PLAYER ID CAPTAIN', 
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BooyahTheme.textMuted, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _captainCtrl, 
            keyboardType: TextInputType.number,
            maxLength: 12, // Membatasi input di keyboard maksimal 12 digit
            style: const TextStyle(color: BooyahTheme.textPri),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Hanya menerima angka
            onChanged: (val) {
              setState(() {
                if (val.isEmpty) {
                  _captainError = null;
                } else if (val.length < 8 || val.length > 12) {
                  _captainError = 'Player ID harus berupa 8 hingga 12 digit';
                } else {
                  _captainError = null;
                }
              });
            },
            decoration: InputDecoration(
              hintText: 'cth: 12345678',
              counterText: '', // Menyembunyikan counter bawaan Flutter agar lebih rapi
              errorText: _captainError,
              prefixIcon: const Icon(Icons.star, color: BooyahTheme.maroonB, size: 18),
            ),
          ),
          const SizedBox(height: 16),
          
          // --- 3. INPUT NO HP (VALIDASI 10-13 DIGIT ANGKA) ---
          const Text(
            'NOMOR HP / WHATSAPP', 
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BooyahTheme.textMuted, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _hpCtrl, 
            keyboardType: TextInputType.phone,
            maxLength: 13, // Membatasi input maksimal 13 digit
            style: const TextStyle(color: BooyahTheme.textPri),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Hanya menerima angka
            onChanged: (val) {
              setState(() {
                if (val.isEmpty) {
                  _hpError = null;
                } else if (val.length < 10 || val.length > 13) {
                  _hpError = 'Nomor HP harus berukuran 10 hingga 13 digit';
                } else {
                  _hpError = null;
                }
              });
            },
            decoration: InputDecoration(
              hintText: 'Untuk kirim Room ID & Password',
              counterText: '',
              errorText: _hpError,
              prefixIcon: const Icon(Icons.phone, color: BooyahTheme.maroonB, size: 18),
            ),
          ),
          const SizedBox(height: 24),
          
          // --- SECTION ANGGOTA ---
          const SectionHeader(title: 'ANGGOTA TIM'),
          const SizedBox(height: 16),
          
          // --- LIST INPUT ANGGOTA DINAMIS (VALIDASI 8-12 DIGIT ANGKA) ---
          ...List.generate(_memberCtrls.length, (index) => Padding(
            key: ValueKey(index),
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PLAYER ID ANGGOTA ${index + 1}', 
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BooyahTheme.textMuted, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // Agar boks icon hapus sejajar saat teks error muncul
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _memberCtrls[index],
                        keyboardType: TextInputType.number,
                        maxLength: 12,
                        style: const TextStyle(color: BooyahTheme.textPri),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (val) {
                          setState(() {
                            if (val.isEmpty) {
                              _memberErrors[index] = null;
                            } else if (val.length < 8 || val.length > 12) {
                              _memberErrors[index] = 'ID Anggota harus berukuran 8-12 digit';
                            } else {
                              _memberErrors[index] = null;
                            }
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Masukkan ID Game anggota ${index + 1}',
                          counterText: '',
                          errorText: _memberErrors[index],
                          prefixIcon: const Icon(Icons.person, color: BooyahTheme.maroonB, size: 18),
                        ),
                      ),
                    ),
                    if (_memberCtrls.length > 1) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeMember(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          decoration: BoxDecoration(
                            color: BooyahTheme.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: BooyahTheme.red.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.close, color: BooyahTheme.red, size: 18),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          )),
          const SizedBox(height: 6),
          
          // --- TOMBOL TAMBAH ANGGOTA (Otomatis Hilang jika sudah mencapai 3 Anggota Tambahan) ---
          if (_memberCtrls.length < 3) ...[
            GestureDetector(
              onTap: _addMember,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(8),
                  color: BooyahTheme.maroon.withValues(alpha: 0.05),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Icon(Icons.add, color: BooyahTheme.maroonB, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'TAMBAH ANGGOTA', 
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: BooyahTheme.maroonB),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          
          // --- TOMBOL SUBMIT ---
          BooyahButton(label: 'LANJUT KE PEMBAYARAN →', onTap: _next),
        ],
      ),
    ),
  );
}