// lib/services/payment_service.dart
// Layanan Midtrans: memanggil Edge Function create-transaction
// dan menyediakan Realtime listener untuk status pembayaran.
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _db = Supabase.instance.client;

class PaymentService {
  // ── Buat Transaksi Midtrans via Edge Function ────────────────────────────
  /// Memanggil Edge Function `create-transaction` dan mengembalikan
  /// { snap_token, redirect_url, order_id }.
  static Future<Map<String, dynamic>> createTransaction({
    required int registrationId,
    required int scrimId,
    required int amount,
    String? teamName,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
  }) async {
    try {
      final response = await _db.functions.invoke(
        'create-transaction',
        body: {
          'registration_id': registrationId,
          'scrim_id': scrimId,
          'amount': amount,
          'team_name': teamName,
          'customer_name': customerName,
          'customer_email': customerEmail,
          'customer_phone': customerPhone,
        },
      );

      if (response.data == null) {
        throw Exception('Tidak ada respons dari server pembayaran');
      }

      final data = Map<String, dynamic>.from(response.data as Map);

      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }

      return data; // { snap_token, redirect_url, order_id }
    } catch (e) {
      debugPrint('PaymentService.createTransaction error: $e');
      rethrow;
    }
  }

  // ── Buat Transaksi Premium Midtrans via Edge Function ────────────────────
  static Future<Map<String, dynamic>> createPremiumTransaction({
    required int premiumRequestId,
    required int amount,
    String? paymentMethod,
  }) async {
    try {
      final response = await _db.functions.invoke(
        'create-transaction',
        body: {
          'premium_request_id': premiumRequestId,
          'amount': amount,
          'payment_method': ?paymentMethod,
        },
      );

      if (response.data == null) {
        throw Exception('Tidak ada respons dari server pembayaran');
      }

      final data = Map<String, dynamic>.from(response.data as Map);

      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }

      return data; // { snap_token, redirect_url, order_id }
    } catch (e) {
      debugPrint('PaymentService.createPremiumTransaction error: $e');
      rethrow;
    }
  }

  // ── Cek Status Pembayaran (polling manual) ───────────────────────────────
  /// Mengambil status terkini dari tabel registrations berdasarkan ID.
  static Future<String?> getPaymentStatus(int registrationId) async {
    try {
      final res = await _db
          .from('registrations')
          .select('status, midtrans_status, payment_type')
          .eq('id', registrationId)
          .single();
      return res['status'] as String?;
    } catch (e) {
      debugPrint('PaymentService.getPaymentStatus error: $e');
      return null;
    }
  }

  // ── Realtime Subscription ─────────────────────────────────────────────────
  /// Berlangganan perubahan status pada baris registration tertentu.
  /// Callback dipanggil setiap kali ada UPDATE dari Midtrans webhook.
  static RealtimeChannel subscribePaymentStatus(
    int registrationId,
    void Function(Map<String, dynamic> updatedRow) onUpdate,
  ) {
    return _db
        .channel('payment_status_$registrationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'registrations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: '$registrationId',
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  // ── URL Snap untuk WebView ────────────────────────────────────────────────
  /// Midtrans Snap embed URL (mode sandbox / production).
  /// Digunakan sebagai src WebView.
  static String snapEmbedUrl(String snapToken, {bool isProduction = false}) {
    final base = isProduction
        ? 'https://app.midtrans.com/snap/v3/redirection'
        : 'https://app.sandbox.midtrans.com/snap/v3/redirection';
    return '$base/$snapToken';
  }
}
