import 'package:flutter/material.dart';
import '../features/auth/welcome_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/main_shell.dart';
import '../features/admin/admin_shell.dart';
import '../features/admin/admin_home_screen.dart';
import '../features/platform/platform_shell.dart';
import '../features/platform/platform_home_screen.dart';
import '../features/booking/booking_screen.dart';
import '../features/booking/detail_scrim_screen.dart';
import '../features/booking/form_tim_screen.dart';
import '../features/booking/pembayaran_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/notification/notification_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/riwayat_scrim_screen.dart';
import '../features/profile/klaim_hadiah_screen.dart';
import '../features/profile/status_pendaftaran_screen.dart';
import '../features/admin/buat_scrim_screen.dart';
import '../features/admin/data_pendaftar_screen.dart';
import '../features/admin/room_id_screen.dart';
import '../features/admin/input_hasil_screen.dart';
import '../features/admin/kirim_pengumuman_screen.dart';
import '../features/admin/laporan_scrim_screen.dart';
import '../features/platform/dashboard_keuangan_screen.dart';
import '../features/platform/manajemen_akun_screen.dart';
import '../features/platform/kelola_premium_screen.dart';
import '../features/platform/verifikasi_klaim_screen.dart';
import '../features/platform/laporan_platform_screen.dart';
import '../shared/models/models.dart';

class AppRoutes {
  // Auth
  static const welcome  = '/welcome';
  static const login    = '/login';
  static const register = '/register';
  // Shells (entry point per role)
  static const pesertaShell  = '/shell/peserta';
  static const adminShell    = '/shell/admin';
  static const platformShell = '/shell/platform';
  // Peserta
  static const booking           = '/booking';
  static const detailScrim       = '/detail-scrim';
  static const formTim           = '/form-tim';
  static const pembayaran        = '/pembayaran';
  static const leaderboard       = '/leaderboard';
  static const notification      = '/notification';
  static const profile           = '/profile';
  static const riwayat           = '/riwayat';
  static const klaimHadiah       = '/klaim-hadiah';
  static const statusPendaftaran = '/status-pendaftaran';
  // Admin
  static const adminHome         = '/admin/home';
  static const buatScrim         = '/buat-scrim';
  static const dataPendaftar     = '/data-pendaftar';
  static const roomId            = '/room-id';
  static const inputHasil        = '/input-hasil';
  static const kirimPengumuman   = '/kirim-pengumuman';
  static const laporanScrim      = '/laporan-scrim';
  // Platform
  static const platformHome      = '/platform/home';
  static const dashKeuangan      = '/dashboard-keuangan';
  static const manajemenAkun     = '/manajemen-akun';
  static const kelolaPremium     = '/kelola-premium';
  static const verifKlaim        = '/verifikasi-klaim';
  static const laporanPlat       = '/laporan-platform';

  static Map<String, WidgetBuilder> get routes => {
    // Auth
    welcome:           (_) => const WelcomeScreen(),
    login:             (_) => const LoginScreen(),
    register:          (_) => const RegisterScreen(),
    // Shells
    pesertaShell:      (_) => const MainShell(),
    adminShell:        (_) => const AdminShell(),
    platformShell:     (_) => const PlatformShell(),
    // Peserta screens
    booking:           (_) => const BookingScreen(),
    detailScrim:       (_) => const DetailScrimScreen(),
    formTim:           (_) => const FormTimScreen(),
    pembayaran:        (_) => const PembayaranScreen(),
    leaderboard:       (_) => const LeaderboardScreen(),
    notification:      (_) => const NotificationScreen(),
    profile:           (_) => const ProfileScreen(),
    riwayat:           (_) => const RiwayatScrimScreen(),
    klaimHadiah:       (_) => const KlaimHadiahScreen(),
    statusPendaftaran: (_) => const StatusPendaftaranScreen(),
    // Admin screens
    adminHome:         (_) => const AdminHomeScreen(),
    buatScrim:         (_) => const BuatScrimScreen(),
    dataPendaftar:     (_) => const DataPendaftarScreen(),
    roomId:            (_) => const RoomIdScreen(),
    inputHasil:        (_) => const InputHasilScreen(),
    kirimPengumuman:   (_) => const KirimPengumumanScreen(),
    laporanScrim:      (_) => const LaporanScrimScreen(),
    // Platform screens
    platformHome:      (_) => const PlatformHomeScreen(),
    dashKeuangan:      (_) => const DashboardKeuanganScreen(),
    manajemenAkun:     (_) => const ManajemenAkunScreen(),
    kelolaPremium:     (_) => const KelolaPremiumScreen(),
    verifKlaim:        (_) => const VerifikasiKlaimScreen(),
    laporanPlat:       (_) => const LaporanPlatformScreen(),
  };

  // Helper: route berdasarkan role setelah login
  static String homeForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:    return adminShell;
      case UserRole.platform: return platformShell;
      default:                return pesertaShell;
    }
  }
}