/// Database Enum Types - Source of Truth for State Management
/// This file contains all custom enum types directly from Supabase PostgreSQL schema
library;

// ============================================
// 1. USER ROLES (user_role)
// ============================================
enum UserRole {
  peserta('peserta'),
  admin('admin'),
  platform('platform');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String? value) {
    if (value == null) return UserRole.peserta;
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.peserta,
    );
  }

  @override
  String toString() => value;
}

// ============================================
// 2. SCRIM MODES (scrim_mode)
// ============================================
enum ScrimMode {
  battleRoyale('battle_royale', 'BR'),
  clashSquad('clash_squad', 'CS');

  final String dbValue;
  final String shortName;

  const ScrimMode(this.dbValue, this.shortName);

  static ScrimMode fromString(String? value) {
    if (value == null) return ScrimMode.battleRoyale;
    return ScrimMode.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => ScrimMode.battleRoyale,
    );
  }

  @override
  String toString() => dbValue;
}

// ============================================
// 3. SCRIM STATUS (scrim_status)
// ============================================
enum ScrimStatus {
  draft('draft', 'Draft', '📝'),
  open('open', 'Buka', '🟢'),
  closed('closed', 'Tutup', '🔴'),
  ongoing('ongoing', 'Berlangsung', '⚡'),
  finished('finished', 'Selesai', '✅'),
  cancelled('cancelled', 'Dibatalkan', '❌');

  final String dbValue;
  final String displayText;
  final String emoji;

  const ScrimStatus(this.dbValue, this.displayText, this.emoji);

  static ScrimStatus fromString(String? value) {
    if (value == null) return ScrimStatus.draft;
    return ScrimStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => ScrimStatus.draft,
    );
  }

  bool get isActive => this == ScrimStatus.open || this == ScrimStatus.ongoing;
  bool get isFinalized => this == ScrimStatus.finished || this == ScrimStatus.cancelled;

  @override
  String toString() => dbValue;
}

// ============================================
// 4. REGISTRATION STATUS (reg_status)
// Automated by Midtrans integration
// ============================================
enum RegistrationStatus {
  pendingPayment('pending_payment', 'Menunggu Pembayaran', '⏳'),
  waitingVerify('waiting_verify', 'Menunggu Verifikasi', '👀'),
  verified('verified', 'Terverifikasi', '✅'),
  rejected('rejected', 'Ditolak', '❌'),
  waitingRoomId('waiting_room_id', 'Menunggu Room ID', '🎮'),
  ongoing('ongoing', 'Berlangsung', '⚡'),
  finished('finished', 'Selesai', '🏁'),
  expired('expired', 'Kadaluarsa', '⏰'), // Midtrans automation
  failed('failed', 'Gagal', '💔'); // Midtrans automation

  final String dbValue;
  final String displayText;
  final String emoji;

  const RegistrationStatus(this.dbValue, this.displayText, this.emoji);

  static RegistrationStatus fromString(String? value) {
    if (value == null) return RegistrationStatus.pendingPayment;
    return RegistrationStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => RegistrationStatus.pendingPayment,
    );
  }

  bool get needsPayment => this == RegistrationStatus.pendingPayment;
  bool get isVerified => this == RegistrationStatus.verified;
  bool get canJoinRoom => this == RegistrationStatus.verified || this == RegistrationStatus.waitingRoomId;

  @override
  String toString() => dbValue;
}

// ============================================
// 5. TRANSACTION TYPE (tx_type)
// ============================================
enum TransactionType {
  registrationFee('registration_fee', 'Biaya Registrasi', '➕'),
  platformFee('platform_fee', 'Biaya Platform', '🏢'),
  adminFee('admin_fee', 'Biaya Admin', '👨‍💼'),
  prizePayout('prize_payout', 'Hadiah Juara', '🏆'),
  premiumFee('premium_fee', 'Biaya Premium', '⭐'),
  refund('refund', 'Pengembalian Dana', '↩️');

  final String dbValue;
  final String displayText;
  final String emoji;

  const TransactionType(this.dbValue, this.displayText, this.emoji);

  static TransactionType fromString(String? value) {
    if (value == null) return TransactionType.registrationFee;
    return TransactionType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => TransactionType.registrationFee,
    );
  }

  bool get isIncoming => this == TransactionType.registrationFee || this == TransactionType.premiumFee;
  bool get isOutgoing => this == TransactionType.platformFee || 
                        this == TransactionType.adminFee ||
                        this == TransactionType.prizePayout ||
                        this == TransactionType.refund;

  @override
  String toString() => dbValue;
}

// ============================================
// 6. CLAIM STATUS (claim_status)
// ============================================
enum ClaimStatus {
  available('available', 'Tersedia', '💰'),
  processing('processing', 'Diproses', '⏳'),
  verified('verified', 'Diverifikasi', '✅'),
  rejected('rejected', 'Ditolak', '❌');

  final String dbValue;
  final String displayText;
  final String emoji;

  const ClaimStatus(this.dbValue, this.displayText, this.emoji);

  static ClaimStatus fromString(String? value) {
    if (value == null) return ClaimStatus.available;
    return ClaimStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => ClaimStatus.available,
    );
  }

  bool get isFinalized => this == ClaimStatus.verified || this == ClaimStatus.rejected;

  @override
  String toString() => dbValue;
}

// ============================================
// 7. BANK TYPE (bank_type)
// ============================================
enum BankType {
  bank('bank', 'Bank Rekening', '🏦'),
  ewallet('ewallet', 'E-Wallet', '📱');

  final String dbValue;
  final String displayText;
  final String emoji;

  const BankType(this.dbValue, this.displayText, this.emoji);

  static BankType fromString(String? value) {
    if (value == null) return BankType.bank;
    return BankType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => BankType.bank,
    );
  }

  @override
  String toString() => dbValue;
}

// ============================================
// 8. NOTIFICATION TYPE (notif_type)
// ============================================
enum NotificationType {
  paymentConfirmed('payment_confirmed', 'Pembayaran Dikonfirmasi', '✅💳'),
  paymentRejected('payment_rejected', 'Pembayaran Ditolak', '❌💳'),
  roomIdSent('room_id_sent', 'Room ID Dikirim', '🎮'),
  scheduleChanged('schedule_changed', 'Jadwal Berubah', '📅'),
  matchResult('match_result', 'Hasil Pertandingan', '📊'),
  prizeProcessing('prize_processing', 'Hadiah Diproses', '⏳🏆'),
  prizeSent('prize_sent', 'Hadiah Dikirim', '✅🏆'),
  announcement('announcement', 'Pengumuman', '📢'),
  bookingReminder('booking_reminder', 'Reminder Booking', '⏰');

  final String dbValue;
  final String displayText;
  final String emoji;

  const NotificationType(this.dbValue, this.displayText, this.emoji);

  static NotificationType fromString(String? value) {
    if (value == null) return NotificationType.announcement;
    return NotificationType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => NotificationType.announcement,
    );
  }

  @override
  String toString() => dbValue;
}
