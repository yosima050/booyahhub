import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/widgets/booyah_widgets.dart';

class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({super.key});
  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  String _method = 'qris';
  bool _fileUploaded = false;
  bool _loading = false;
  int _timerSecs = 14 * 60 + 32;

  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _timerSecs <= 0) return false;
      setState(() => _timerSecs--);
      return true;
    });
  }

  String get _timerStr {
    final m = _timerSecs ~/ 60;
    final s = _timerSecs % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  void _submit() async {
    if (!_fileUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Upload bukti pembayaran terlebih dahulu!'),
              ),
            ],
          ),
          backgroundColor: BooyahTheme.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _loading = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: BooyahTheme.card,
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PENDAFTARAN DIKIRIM!',
                  style: TextStyle(
                    fontFamily:'Orbitron',
                    fontSize:14,
                    fontWeight:FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Status: Menunggu Verifikasi Admin.\nKamu akan mendapat notifikasi setelah diverifikasi.',
            style: TextStyle(
              fontSize: 12,
              color: BooyahTheme.textSec,
              height: 1.5,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (r) => r.isFirst);
              },
              child: const Text('KEMBALI KE BERANDA'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
      title: const Text('PEMBAYARAN'),
      actions: [const Padding(
        padding: EdgeInsets.only(right: 14),
        child: Center(
          child: Text(
            '2 / 2',
            style: TextStyle(
              fontSize: 12,
              color: BooyahTheme.textMuted,
            ),
          ),
        ),
      )],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: BooyahTheme.yellow.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: BooyahTheme.yellow.withValues(alpha: 0.35),
              ),
            ),
            child: Row(children: [
              const Icon(Icons.timer_outlined, color: BooyahTheme.yellow, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Batas waktu pembayaran',
                  style: TextStyle(fontSize: 11, color: BooyahTheme.yellow),
                ),
              ),
              Text(
                _timerStr,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: BooyahTheme.yellow,
                ),
              ),
            ]),
          ),

          const SectionHeader(title: 'TOTAL BAYAR'),

          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: BooyahTheme.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: BooyahTheme.maroon.withValues(alpha: 0.25),
              ),
            ),
            child: const Column(children: [
              _SummaryRow('Biaya Pendaftaran', 'Rp25.000'),
              _SummaryRow('Biaya Platform', 'Rp0'),
              _SummaryRow('TOTAL BAYAR', 'Rp25.000'),
            ]),
          ),

          const SectionHeader(title: 'METODE PEMBAYARAN'),

          Row(children: [
            Expanded(
              child: _methodCard(
                'qris',
                const Icon(Icons.qr_code_2, size: 26, color: Colors.white),
                'QRIS',
                'GoPay / OVO / DANA',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _methodCard(
                'transfer',
                const Icon(Icons.account_balance, size: 26, color: Colors.white),
                'TRANSFER BANK',
                'BCA / BRI / BNI',
              ),
            ),
          ]),

          const SizedBox(height: 14),

          if (_method == 'qris') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BooyahTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: BooyahTheme.maroon.withValues(alpha: 0.25),
                ),
              ),
              child: Column(children: [
                const Text(
                  'SCAN QRIS UNTUK MEMBAYAR',
                  style: TextStyle(
                    fontSize: 10,
                    color: BooyahTheme.textMuted,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 120, color: Colors.black54),
                        Text(
                          'BOOYAHHUB',
                          style: TextStyle(
                            fontFamily:'Orbitron',
                            fontSize:10,
                            color: Colors.black54,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Rp25.000',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: BooyahTheme.gold,
                  ),
                ),

                const Text(
                  'Berlaku untuk: FIRE WOLVES · Booyah Cup S7',
                  style: TextStyle(
                    fontSize: 10,
                    color: BooyahTheme.textMuted,
                  ),
                ),
              ]),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: BooyahTheme.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: BooyahTheme.maroon.withValues(alpha: 0.25),
                ),
              ),
              child: Column(children: [

                Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: BooyahTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.account_balance,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BCA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Transfer Bank',
                        style: TextStyle(
                          fontSize: 10,
                          color: BooyahTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ]),

                const Divider(height: 20, color: Colors.white12),

                _bankRow('Nama Rekening', 'BOOYAHHUB ID'),
                const SizedBox(height: 8),
                _bankRow('Nomor Rekening', '1234567890'),
                const SizedBox(height: 8),
                _bankRow(
                  'Jumlah Transfer',
                  'Rp25.000',
                  valColor: BooyahTheme.gold,
                ),
              ]),
            ),
          ],

          const SizedBox(height: 14),

          const SectionHeader(title: 'UPLOAD BUKTI BAYAR'),

          GestureDetector(
            onTap: () => setState(() => _fileUploaded = !_fileUploaded),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: _fileUploaded
                    ? BooyahTheme.green.withValues(alpha: 0.05)
                    : BooyahTheme.maroon.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _fileUploaded
                      ? BooyahTheme.green
                      : BooyahTheme.maroon.withValues(alpha: 0.4),
                  width: _fileUploaded ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Icon(
                    _fileUploaded
                        ? Icons.photo_camera
                        : Icons.cloud_upload_outlined,
                    size: 36,
                    color: _fileUploaded
                        ? BooyahTheme.green
                        : BooyahTheme.maroonB,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _fileUploaded
                        ? 'Foto Terupload!'
                        : 'Upload Bukti Pembayaran',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (!_fileUploaded)
                    const Text(
                      'Tap untuk upload',
                      style: TextStyle(
                        fontSize: 10,
                        color: BooyahTheme.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (_fileUploaded) ...[
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: BooyahTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: BooyahTheme.green.withValues(alpha: 0.35),
                ),
              ),
              child: Row(children: [

                const Icon(
                  Icons.image,
                  size: 22,
                  color: BooyahTheme.green,
                ),

                const SizedBox(width: 10),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'bukti_transfer.jpg',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '1.2 MB · JPG',
                        style: TextStyle(
                          fontSize: 10,
                          color: BooyahTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                GestureDetector(
                  onTap: () => setState(() => _fileUploaded = false),
                  child: const Icon(
                    Icons.close,
                    color: BooyahTheme.textMuted,
                    size: 18,
                  ),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 20),

          BooyahButton(
            label: 'KIRIM KONFIRMASI PEMBAYARAN',
            onTap: _submit,
            isLoading: _loading,
            color: _fileUploaded ? const Color(0xFF1a5c1a) : null,
          ),

          const SizedBox(height: 20),
        ],
      ),
    ),
  );

  Widget _methodCard(
    String val,
    Widget ico,
    String name,
    String desc,
  ) => GestureDetector(
    onTap: () => setState(() => _method = val),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _method == val
            ? BooyahTheme.maroon.withValues(alpha: 0.15)
            : BooyahTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _method == val
              ? BooyahTheme.maroonB
              : BooyahTheme.maroon.withValues(alpha: 0.2),
          width: _method == val ? 1.5 : 1,
        ),
      ),
      child: Column(children: [

        ico,

        const SizedBox(height: 6),

        Text(
          name,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),

        Text(
          desc,
          style: const TextStyle(
            fontSize: 9,
            color: BooyahTheme.textMuted,
          ),
          textAlign: TextAlign.center,
        ),

        if (_method == val) ...[
          const SizedBox(height: 4),

          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check,
                size: 12,
                color: BooyahTheme.maroonB,
              ),
              SizedBox(width: 4),
              Text(
                'DIPILIH',
                style: TextStyle(
                  fontSize: 9,
                  color: BooyahTheme.maroonB,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ]),
    ),
  );

  Widget _bankRow(
    String label,
    String val, {
    Color? valColor,
  }) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: BooyahTheme.textMuted,
        ),
      ),
      Text(
        val,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: valColor ?? BooyahTheme.textSec,
        ),
      ),
    ],
  );
}

class _SummaryRow extends StatelessWidget {
  final String label, value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: BooyahTheme.textMuted,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: BooyahTheme.textSec,
          ),
        ),
      ],
    ),
  );
}