import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/booyah_widgets.dart';
import '../../services/supabase_service.dart';
import '../../services/payment_service.dart';

// ──────────────────────────────────────────────────────────────
// PEMBAYARAN SCREEN (Midtrans Snap Integration)
// Flow:
//   1. Terima args dari FormTimScreen
//   2. Panggil RegistrationService.book() → buat draft di DB
//   3. Panggil PaymentService.createTransaction() → dapat snap_token
//   4. Buka Snap via WebView
//   5. Supabase Realtime update status → tampilkan dialog hasil
// ──────────────────────────────────────────────────────────────

class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({super.key});
  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

enum _PayStep { loading, showPayment, processing, success, failed }

class _PembayaranScreenState extends State<PembayaranScreen> {
  // Args dari FormTimScreen
  ScrimModel? _scrim;
  String _teamName = '';
  String _captainFfId = '';
  String _phone = '';
  List<String> _members = [];

  // State
  _PayStep _step = _PayStep.loading;
  String? _error;
  int? _registrationId;
  String? _snapToken;
  late WebViewController _webCtrl;
  RealtimeChannel? _realtimeChannel;

  // Timer countdown (15 menit)
  int _timerSecs = 15 * 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_step == _PayStep.loading && _scrim == null) {
      _readArgs();
    }
  }

  void _readArgs() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _scrim = args['scrim'] as ScrimModel?;
      _teamName = (args['team_name'] as String?) ?? '';
      _captainFfId = (args['captain_ff_id'] as String?) ?? '';
      _phone = (args['phone'] as String?) ?? '';
      _members = List<String>.from(args['members'] as List? ?? []);
    }
    _initPayment();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _timerSecs <= 0) return false;
      setState(() => _timerSecs--);
      if (_timerSecs == 0 && _step == _PayStep.showPayment) {
        _onExpired();
      }
      return true;
    });
  }

  // ── Step 1 & 2: book + buat token ───────────────────────────────────────
  Future<void> _initPayment() async {
    if (_scrim == null) {
      setState(() {
        _error = 'Data scrim tidak ditemukan. Kembali dan coba lagi.';
        _step = _PayStep.failed;
      });
      return;
    }

    setState(() => _step = _PayStep.loading);

    try {
      // 1. Buat draft pendaftaran di DB
      final reg = await RegistrationService.book(
        scrimId: int.parse(_scrim!.id),
        teamName: _teamName,
        captainFfId: _captainFfId,
        phone: _phone,
        paymentAmount: _scrim!.fee,
        members: _members,
      );
      _registrationId = reg['id'] as int;

      // 2. Minta snap_token dari Edge Function
      final user = AuthService.currentUser;
      final payData = await PaymentService.createTransaction(
        registrationId: _registrationId!,
        scrimId: int.parse(_scrim!.id),
        amount: _scrim!.fee,
        teamName: _teamName,
        customerEmail: user?.email,
      );

      _snapToken = payData['snap_token'] as String?;

      if (_snapToken == null) throw Exception('Snap token tidak diterima');

      // 3. Setup WebView untuk Snap
      _setupWebView();

      // 4. Subscribe Realtime untuk status
      _subscribeStatus();

      setState(() => _step = _PayStep.showPayment);
    } catch (e) {
      debugPrint('_initPayment error: $e');
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _step = _PayStep.failed;
      });
    }
  }

  void _setupWebView() {
    final snapUrl = PaymentService.snapEmbedUrl(_snapToken!);
    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(BooyahTheme.bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _step = _PayStep.processing),
          onPageFinished: (_) => setState(() => _step = _PayStep.showPayment),
          onNavigationRequest: (req) {
            // Midtrans mengirim deep link / callback URL setelah bayar
            if (req.url.contains('payment_type') ||
                req.url.contains('transaction_status') ||
                req.url.contains('finish') ||
                req.url.contains('error') ||
                req.url.contains('unfinish')) {
              _handleSnapCallback(req.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(snapUrl));
  }

  void _subscribeStatus() {
    if (_registrationId == null) return;
    _realtimeChannel = PaymentService.subscribePaymentStatus(_registrationId!, (
      row,
    ) {
      final status = row['status'] as String?;
      if (status == 'verified') {
        _onSuccess();
      } else if (status == 'expired' || status == 'failed') {
        _onFailed('Pembayaran gagal atau kedaluwarsa.');
      }
    });
  }

  void _handleSnapCallback(String url) {
    if (url.contains('finish') ||
        url.contains('transaction_status=settlement') ||
        url.contains('transaction_status=capture')) {
      _onSuccess();
    } else if (url.contains('error') ||
        url.contains('transaction_status=deny') ||
        url.contains('transaction_status=cancel')) {
      _onFailed('Pembayaran dibatalkan atau ditolak.');
    } else {
      // unfinish — user tutup Snap tanpa selesai
      setState(() => _step = _PayStep.showPayment);
    }
  }

  void _onSuccess() {
    if (!mounted) return;
    setState(() => _step = _PayStep.success);
    _showResultDialog(success: true);
  }

  void _onFailed(String reason) {
    if (!mounted) return;
    setState(() {
      _error = reason;
      _step = _PayStep.failed;
    });
    _showResultDialog(success: false);
  }

  void _onExpired() {
    _onFailed('Waktu pembayaran habis. Silakan daftar ulang.');
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  // ── Timer ────────────────────────────────────────────────────────────────
  String get _timerStr {
    final m = _timerSecs ~/ 60;
    final s = _timerSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Dialog Hasil ─────────────────────────────────────────────────────────
  void _showResultDialog({required bool success}) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: BooyahTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.cancel,
              color: success ? BooyahTheme.green : BooyahTheme.red,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                success ? 'PEMBAYARAN BERHASIL!' : 'PEMBAYARAN GAGAL',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          success
              ? 'Tim kamu berhasil terdaftar di ${_scrim?.title ?? 'scrim ini'}!\nKamu akan mendapat notifikasi dari admin.'
              : (_error ?? 'Terjadi kesalahan. Silakan coba lagi.'),
          style: const TextStyle(
            fontSize: 12,
            color: BooyahTheme.textSec,
            height: 1.6,
          ),
        ),
        actions: [
          if (success) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // tutup dialog
                Navigator.popUntil(context, (r) => r.isFirst);
                Navigator.pushNamed(context, AppRoutes.statusPendaftaran);
              },
              child: const Text(
                'LIHAT STATUS',
                style: TextStyle(color: BooyahTheme.green, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // tutup dialog
                Navigator.popUntil(context, (r) => r.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BooyahTheme.green,
              ),
              child: const Text('BERANDA'),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: BooyahTheme.maroon,
              ),
              child: const Text('OK'),
            ),
          ]
        ],
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PEMBAYARAN'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                '2 / 2',
                style: const TextStyle(
                  fontSize: 12,
                  color: BooyahTheme.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case _PayStep.loading:
        return _buildLoading();
      case _PayStep.showPayment:
      case _PayStep.processing:
        return _buildPaymentView();
      case _PayStep.success:
        return _buildSuccessView();
      case _PayStep.failed:
        return _buildFailedView();
    }
  }

  // ── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: BooyahTheme.maroonB),
          const SizedBox(height: 20),
          const Text(
            'Menyiapkan pembayaran...',
            style: TextStyle(color: BooyahTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Menghubungi server Midtrans',
            style: TextStyle(
              color: BooyahTheme.textMuted.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── WebView (Snap) ────────────────────────────────────────────────────────
  Widget _buildPaymentView() {
    return Column(
      children: [
        // Timer bar
        _TimerBanner(timerStr: _timerStr, secs: _timerSecs),

        // Info ringkas
        _OrderSummaryBanner(scrim: _scrim, teamName: _teamName),

        // Snap WebView
        Expanded(
          child: Stack(
            children: [
              WebViewWidget(controller: _webCtrl),
              if (_step == _PayStep.processing)
                Container(
                  color: BooyahTheme.bg.withValues(alpha: 0.6),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: BooyahTheme.maroonB,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Success ───────────────────────────────────────────────────────────────
  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: BooyahTheme.green, size: 72),
            const SizedBox(height: 20),
            const Text(
              'PEMBAYARAN BERHASIL!',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: BooyahTheme.green,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tim ${_teamName.toUpperCase()} telah terdaftar.\nAdmin akan memverifikasi segera.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: BooyahTheme.textSec,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            BooyahButton(
              label: 'KEMBALI KE BERANDA',
              onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
              color: BooyahTheme.green,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.popUntil(context, (r) => r.isFirst);
                Navigator.pushNamed(context, AppRoutes.statusPendaftaran);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: BooyahTheme.green, width: 1.5),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'LIHAT STATUS PENDAFTARAN',
                style: TextStyle(color: BooyahTheme.green, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Failed ────────────────────────────────────────────────────────────────
  Widget _buildFailedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel_rounded, color: BooyahTheme.red, size: 72),
            const SizedBox(height: 20),
            const Text(
              'PEMBAYARAN GAGAL',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: BooyahTheme.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Terjadi kesalahan. Silakan coba lagi.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: BooyahTheme.textSec,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            BooyahButton(
              label: 'COBA LAGI',
              onTap: () => _initPayment(),
              color: BooyahTheme.maroon,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text(
                'Kembali ke Beranda',
                style: TextStyle(color: BooyahTheme.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _TimerBanner extends StatelessWidget {
  final String timerStr;
  final int secs;
  const _TimerBanner({required this.timerStr, required this.secs});

  @override
  Widget build(BuildContext context) {
    final urgent = secs < 3 * 60; // < 3 menit → merah
    final color = urgent ? BooyahTheme.red : BooyahTheme.yellow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: color, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Selesaikan pembayaran sebelum',
              style: TextStyle(fontSize: 11, color: color),
            ),
          ),
          Text(
            timerStr,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryBanner extends StatelessWidget {
  final ScrimModel? scrim;
  final String teamName;
  const _OrderSummaryBanner({required this.scrim, required this.teamName});

  @override
  Widget build(BuildContext context) {
    if (scrim == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: BooyahTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BooyahTheme.maroon.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scrim!.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BooyahTheme.textPri,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Tim: ${teamName.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: BooyahTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Rp${scrim!.fee ~/ 1000}k',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: BooyahTheme.gold,
            ),
          ),
        ],
      ),
    );
  }
}
