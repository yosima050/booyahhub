import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
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

  void _addMember() {
    setState(() => _memberCtrls.add(TextEditingController()));
  }

  void _removeMember(int idx) => setState(() => _memberCtrls.removeAt(idx));

  void _next() {
    if (_namaCtrl.text.isEmpty || _captainCtrl.text.isEmpty || _hpCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nama tim, ID Captain, dan HP wajib diisi!',
                ),
              ),
            ],
          ),
          backgroundColor: BooyahTheme.red,
        ),
      );
      return;
    }
    Navigator.pushNamed(context, AppRoutes.pembayaran);
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
          
          // --- 2. INPUT ID CAPTAIN ---
          const Text(
            'PLAYER ID CAPTAIN', 
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BooyahTheme.textMuted, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _captainCtrl, 
            style: const TextStyle(color: BooyahTheme.textPri),
            decoration: const InputDecoration(
              hintText: 'cth: 123456789 (ID Game)',
              prefixIcon: Icon(Icons.star, color: BooyahTheme.maroonB, size: 18),
            ),
          ),
          const SizedBox(height: 16),
          
          // --- 3. INPUT NO HP ---
          const Text(
            'NOMOR HP / WHATSAPP', 
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BooyahTheme.textMuted, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _hpCtrl, 
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: BooyahTheme.textPri),
            decoration: const InputDecoration(
              hintText: 'Untuk kirim Room ID & Password',
              prefixIcon: Icon(Icons.phone, color: BooyahTheme.maroonB, size: 18),
            ),
          ),
          const SizedBox(height: 24),
          
          // --- SECTION ANGGOTA ---
          const SectionHeader(title: 'ANGGOTA TIM'),
          const SizedBox(height: 16),
          
          // --- LIST INPUT ANGGOTA DINAMIS ---
          ...List.generate(_memberCtrls.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PLAYER ID ANGGOTA ${i + 1}', 
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BooyahTheme.textMuted, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _memberCtrls[i],
                        style: const TextStyle(color: BooyahTheme.textPri),
                        decoration: InputDecoration(
                          hintText: 'Masukkan ID Free Fire anggota ${i + 1}',
                          prefixIcon: const Icon(Icons.person, color: BooyahTheme.maroonB, size: 18),
                        ),
                      ),
                    ),
                    if (_memberCtrls.length > 1) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeMember(i),
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
          
          // --- TOMBOL TAMBAH ANGGOTA ---
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