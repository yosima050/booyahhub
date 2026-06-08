import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../core/auth_service.dart';
import '../../shared/models/models.dart';
import '../../services/supabase_service.dart' hide AuthService;
import '../../services/payment_service.dart';

class AdminSubscriptionScreen extends StatefulWidget {
  const AdminSubscriptionScreen({super.key});

  @override
  State<AdminSubscriptionScreen> createState() =>
      _AdminSubscriptionScreenState();
}

class _AdminSubscriptionScreenState extends State<AdminSubscriptionScreen> {
  int _selectedPlan = 1;
  int _selectedPayment = 0;

  Map<String, dynamic>? _userData;
  bool _loadingSub = true;
  bool _loadingPay = false;

  String? _snapToken;
  WebViewController? _webCtrl;
  bool _showWebView = false;
  RealtimeChannel? _realtimeSub;
  String? _error;

  final plans = [
    {
      'name': 'BULANAN',
      'price': 49000,
      'duration': '30 Hari',
      'db_package': '1_month',
    },
    {
      'name': '3 BULAN',
      'price': 129000,
      'duration': '90 Hari',
      'db_package': '3_months',
    },
    {
      'name': 'TAHUNAN',
      'price': 399000,
      'duration': '365 Hari',
      'db_package': '1_year',
    },
  ];

  final payments = ['GoPay', 'shopeepay'];

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  @override
  void dispose() {
    _realtimeSub?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadSubscription() async {
    try {
      if (mounted) setState(() => _loadingSub = true);
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userData = await UserService.getUserProfile(user.id);
        if (mounted) {
          setState(() {
            _userData = userData;
            _loadingSub = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading sub: $e');
      if (mounted) setState(() => _loadingSub = false);
    }
  }

  Future<void> _paySubscription() async {
    final int adminId = _userData?['id'] as int? ?? 0;
    if (adminId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil admin tidak ditemukan')),
      );
      return;
    }

    final selectedPlan = plans[_selectedPlan];
    final packageType = selectedPlan['db_package'] as String;
    final amount = selectedPlan['price'] as int;

    setState(() {
      _loadingPay = true;
      _error = null;
    });

    try {
      // 1. Buat premium_requests di DB
      final req = await Supabase.instance.client
          .from('premium_requests')
          .insert({
            'admin_user_id': adminId,
            'amount': amount,
            'package_type': packageType,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final int requestId = req['id'] as int;

      final selectedPaymentMethod = payments[_selectedPayment]
          .toLowerCase()
          .replaceAll(' ', '_');
      String mappedMethod = selectedPaymentMethod;
      if (selectedPaymentMethod == 'transfer_bank')
        mappedMethod = 'bank_transfer';

      // 2. Minta Snap Token dari Edge Function
      final tx = await PaymentService.createPremiumTransaction(
        premiumRequestId: requestId,
        amount: amount,
        paymentMethod: mappedMethod,
      );

      _snapToken = tx['snap_token'] as String?;

      if (_snapToken == null) throw Exception('Snap token tidak diterima');

      // 3. Setup WebView
      _setupWebView();

      // 4. Subscribe realtime status
      _subscribeStatus(requestId);

      setState(() {
        _showWebView = true;
        _loadingPay = false;
      });
    } catch (e) {
      debugPrint('Error paying subscription: $e');
      setState(() => _loadingPay = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
    }
  }

  void _setupWebView() {
    final snapUrl = PaymentService.snapEmbedUrl(_snapToken!);
    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(BooyahTheme.bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
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

  void _subscribeStatus(int requestId) {
    _realtimeSub = Supabase.instance.client
        .channel('premium_status_$requestId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'premium_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: '$requestId',
          ),
          callback: (payload) {
            final status = payload.newRecord['status'] as String?;
            if (status == 'approved') {
              _onSuccess();
            } else if (status == 'rejected') {
              _onFailed('Pembayaran gagal atau kedaluwarsa.');
            }
          },
        )
        .subscribe();
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
      setState(() => _showWebView = true);
    }
  }

  void _onSuccess() {
    if (!mounted) return;
    _realtimeSub?.unsubscribe();
    _realtimeSub = null;
    setState(() {
      _showWebView = false;
      _snapToken = null;
      _webCtrl = null;
    });
    _loadSubscription();
    _showResultDialog(success: true);
  }

  void _onFailed(String reason) {
    if (!mounted) return;
    _realtimeSub?.unsubscribe();
    _realtimeSub = null;
    setState(() {
      _showWebView = false;
      _snapToken = null;
      _webCtrl = null;
      _error = reason;
    });
    _showResultDialog(success: false);
  }

  void _showResultDialog({required bool success}) {
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
                success ? 'SUKSES LANGGANAN!' : 'PEMBAYARAN GAGAL',
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
              ? (_userData?['role']?.toString().toLowerCase() == 'admin'
                    ? 'Selamat! Subscription Premium Admin Anda telah diperpanjang.\nDashboard dan fitur admin kini aktif kembali.'
                    : 'Selamat! Pembelian Premium Admin berhasil.\nAnda kini beralih ke Mode Admin.')
              : (_error ?? 'Terjadi kesalahan saat memproses pembayaran.'),
          style: const TextStyle(
            fontSize: 12,
            color: BooyahTheme.textSec,
            height: 1.6,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (success) {
                // Update client-side role
                AuthService().updateRole(UserRole.admin);
                // Redirect immediately to admin shell
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.adminShell,
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: success ? BooyahTheme.green : BooyahTheme.maroon,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String rupiah(int amount) {
    final formatter = amount.toString().split('').reversed.toList();
    String result = '';
    for (int i = 0; i < formatter.length; i++) {
      if (i > 0 && i % 3 == 0) {
        result += '.';
      }
      result += formatter[i];
    }
    return 'Rp${result.split('').reversed.join('')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_showWebView && _webCtrl != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PEMBAYARAN SUBSCRIPTION'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _realtimeSub?.unsubscribe();
              _realtimeSub = null;
              setState(() {
                _showWebView = false;
                _webCtrl = null;
                _snapToken = null;
              });
            },
          ),
        ),
        body: WebViewWidget(controller: _webCtrl!),
      );
    }

    if (_loadingSub) {
      return Scaffold(
        appBar: AppBar(title: const Text('ADMIN SUBSCRIPTION')),
        body: const Center(
          child: CircularProgressIndicator(color: BooyahTheme.yellow),
        ),
      );
    }

    dynamic adminProfData = _userData?['admin_profiles'];
    Map<String, dynamic>? adminProfile;
    if (adminProfData is List && adminProfData.isNotEmpty) {
      adminProfile = adminProfData.first as Map<String, dynamic>?;
    } else if (adminProfData is Map) {
      adminProfile = Map<String, dynamic>.from(adminProfData);
    }
    final bool isPremium = adminProfile?['is_premium'] as bool? ?? false;
    final String? expiredAtStr = adminProfile?['premium_expired_at'] as String?;

    bool isPremiumActive = false;
    int remainingDays = 0;
    if (isPremium && expiredAtStr != null) {
      final expiredAt = DateTime.parse(expiredAtStr);
      remainingDays = expiredAt.difference(DateTime.now()).inDays;
      if (remainingDays > 0) {
        isPremiumActive = true;
      }
    }

    final selected = plans[_selectedPlan];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _userData?['role']?.toString().toLowerCase() == 'admin'
              ? 'ADMIN SUBSCRIPTION'
              : 'BELI SUBSCRIPTION ADMIN',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //----------------------------------
            // STATUS PREMIUM
            //----------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5C0000), Color(0xFF1A0000)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: BooyahTheme.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPremiumActive
                        ? Icons.workspace_premium
                        : Icons.gpp_maybe_rounded,
                    color: isPremiumActive
                        ? BooyahTheme.gold
                        : BooyahTheme.textMuted,
                    size: 40,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremiumActive
                              ? 'PREMIUM AKTIF'
                              : 'BASIC / TIDAK AKTIF',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPremiumActive
                              ? '$remainingDays Hari Tersisa'
                              : 'Silakan beli paket premium',
                          style: TextStyle(
                            color: isPremiumActive
                                ? BooyahTheme.gold
                                : BooyahTheme.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            //----------------------------------
            // PAKET
            //----------------------------------
            const Text(
              'PILIH PAKET',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),

            ...plans.asMap().entries.map((e) {
              final selectedCard = _selectedPlan == e.key;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPlan = e.key;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selectedCard
                        ? BooyahTheme.gold.withValues(alpha: 0.08)
                        : BooyahTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedCard
                          ? BooyahTheme.gold
                          : BooyahTheme.maroon.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedCard
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: selectedCard
                            ? BooyahTheme.gold
                            : BooyahTheme.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.value['name'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              e.value['duration'].toString(),
                              style: const TextStyle(
                                color: BooyahTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        rupiah(e.value['price'] as int),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: BooyahTheme.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 10),

            //----------------------------------
            // PAYMENT
            //----------------------------------
            const Text(
              'METODE PEMBAYARAN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: payments.asMap().entries.map((e) {
                final selectedMethod = _selectedPayment == e.key;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPayment = e.key;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selectedMethod
                          ? BooyahTheme.gold.withValues(alpha: 0.1)
                          : BooyahTheme.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedMethod
                            ? BooyahTheme.gold
                            : BooyahTheme.maroon.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selectedMethod
                            ? BooyahTheme.gold
                            : BooyahTheme.textPri,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            //----------------------------------
            // SUMMARY
            //----------------------------------
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: BooyahTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: BooyahTheme.maroon.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  _row('Paket', selected['name'].toString()),
                  const SizedBox(height: 10),
                  _row('Durasi', selected['duration'].toString()),
                  const Divider(),
                  _row('Total', rupiah(selected['price'] as int)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            //----------------------------------
            // BUTTON
            //----------------------------------
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loadingPay ? null : _paySubscription,
                icon: _loadingPay
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.payment),
                label: Text(
                  _userData?['role']?.toString().toLowerCase() == 'admin'
                      ? 'PERPANJANG SUBSCRIPTION'
                      : 'BELI SUBSCRIPTION ADMIN',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BooyahTheme.gold,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String title, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: BooyahTheme.textMuted),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
