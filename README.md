# 🎮 BooyahHub — E-Sports Scrim & Tournament Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Powered-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Midtrans](https://img.shields.io/badge/Midtrans-Integrated-011F4B)](https://midtrans.com)
[![Platform](https://img.shields.io/badge/Platform-Android-orange)](https://github.com/yosima050/booyahhub)

**BooyahHub** adalah platform manajemen scrim dan turnamen e-sports mobile (Free Fire & game mobile lainnya) yang memisahkan peran antara:

- 🎯 **Peserta** — Daftar scrim, bayar, pantau status & klaim hadiah
- 🛠️ **Admin** — Buat scrim, kelola peserta, input hasil, kirim pengumuman
- 👑 **Platform Owner** — Dashboard keuangan, kelola akun admin, verifikasi hadiah

---

## ✨ Fitur Utama

### 🎯 Peserta (User App)
| Fitur | Keterangan |
|---|---|
| Daftar Scrim | Pendaftaran tim dengan upload bukti bayar via Midtrans Snap |
| Status Pendaftaran | Pantau status booking & konfirmasi pembayaran secara real-time |
| Riwayat Scrim | Lihat semua scrim yang pernah diikuti beserta hasil |
| Klaim Hadiah | Ajukan klaim hadiah setelah scrim selesai |
| Rekening & E-Wallet | Simpan nomor rekening/e-wallet untuk proses pembayaran lebih cepat |
| Riwayat Pembayaran | Lihat semua riwayat transaksi (biaya registrasi, hadiah, dll.) |
| Notifikasi Push | Terima notifikasi real-time via Firebase Cloud Messaging (FCM) |
| Leaderboard | Peringkat peserta berdasarkan kill dan total hadiah |

### 🛠️ Admin (Admin App)
| Fitur | Keterangan |
|---|---|
| Dashboard Scrim | Lihat semua scrim yang dibuat, dengan filter Semua / Selesai |
| Buat Scrim | Form lengkap pembuatan scrim (slot, prize, jadwal, dll.) |
| Kelola Scrim | Edit, atur status, lihat data pendaftar |
| Input Room ID | Input ID room dan password game ke peserta |
| Input Hasil | Upload hasil scrim per tim (ranking, kills, hadiah) |
| Laporan Scrim | Ringkasan laporan keseluruhan scrim |
| Kirim Pengumuman | Broadcast notifikasi ke semua peserta scrim |
| Subscription Premium | Akses fitur premium admin dengan subscription berbayar |

### 👑 Platform Owner
| Fitur | Keterangan |
|---|---|
| Dashboard Keuangan | Monitor total pendapatan, scrim aktif, dan tim terdaftar |
| Kelola Admin | Manajemen akun admin dan status premium |
| Verifikasi Hadiah | Validasi dan approve klaim hadiah peserta |
| Statistik Platform | Data agregat seluruh aktivitas platform |

---

## 🏗️ Arsitektur & Teknologi

```
booyahhub/
├── lib/
│   ├── core/           # Theme, routing, auth service
│   ├── config/         # Konfigurasi Supabase (⚠️ tidak di-commit)
│   ├── features/
│   │   ├── admin/      # Semua screen admin (buat scrim, input hasil, dll.)
│   │   ├── auth/       # Login & registrasi
│   │   ├── booking/    # Alur pendaftaran scrim
│   │   ├── home/       # Halaman utama peserta
│   │   ├── leaderboard/# Papan peringkat
│   │   ├── notification/# Notifikasi in-app
│   │   ├── platform/   # Dashboard platform owner
│   │   ├── profile/    # Profil, riwayat, klaim hadiah
│   │   └── search/     # Pencarian scrim
│   ├── services/       # Supabase queries, payment, push notification
│   └── shared/         # Models, widgets, enums
├── supabase/
│   ├── functions/      # Edge Functions (⚠️ tidak di-commit)
│   │   ├── create-transaction/  # Buat token Midtrans Snap
│   │   ├── payment-notification/# Webhook Midtrans + role sync
│   │   └── send-push/           # Kirim notifikasi FCM
│   └── migrations/     # Schema database (PostgreSQL)
└── android/
    └── app/src/        # google-services.json (⚠️ tidak di-commit)
```

### Stack Teknologi
| Layer | Teknologi |
|---|---|
| Frontend | Flutter 3.x (Dart) |
| Backend / Database | Supabase (PostgreSQL + Realtime) |
| Auth | Supabase Auth (email + Google OAuth) |
| Payment | Midtrans Snap (WebView) |
| Push Notification | Firebase Cloud Messaging (FCM) |
| Edge Functions | Deno / TypeScript (Supabase Edge Runtime) |
| Storage | Supabase Storage (avatar, bukti bayar) |

---

## 🛠️ Panduan Setup & Instalasi

### Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.11
- [Supabase CLI](https://supabase.com/docs/guides/cli) (untuk deploy edge functions)
- Android SDK / Android Studio
- Akun [Supabase](https://supabase.com), [Firebase](https://firebase.google.com), dan [Midtrans](https://midtrans.com)

---

### 1. Clone Repositori
```sh
git clone https://github.com/yosima050/booyahhub.git
cd booyahhub
```

### 2. Buat File Konfigurasi Rahasia

> ⚠️ File-file ini tidak disertakan di repo karena berisi data sensitif. Minta kepada pemilik repo atau buat sesuai format di bawah.

#### `lib/config/supabase_config.dart`
```dart
class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT_ID.supabase.co');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY');
}
```
> Dapatkan nilai dari: **Supabase Dashboard → Settings → API**

#### `android/app/src/google-services.json`
> Download dari: **Firebase Console → Project Settings → Your Apps → Android App**

---

### 3. Install Dependensi Flutter
```bash
flutter pub get
```

### 4. Jalankan Aplikasi

```bash
# Android (Peserta / Admin)
flutter run -d android
```

---

## ⚡ Setup Supabase & Edge Functions

### 1. Login Supabase CLI
```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

### 2. Jalankan Database Migrations
```bash
supabase db push
```

### 3. Set Secrets di Supabase
```bash
# Midtrans
supabase secrets set MIDTRANS_SERVER_KEY=SB-Mid-server-xxxxx
supabase secrets set MIDTRANS_IS_PRODUCTION=false

# Webhook security
supabase secrets set WEBHOOK_SECRET=your_secret_string

# Firebase Service Account (untuk FCM)
# Dapatkan dari Firebase Console → Project Settings → Service Accounts → Generate new private key
supabase secrets set FIREBASE_SERVICE_ACCOUNT='{"type":"service_account","project_id":"...","private_key":"..."}'

# Supabase Service Role Key (untuk admin operations di edge functions)
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### 4. Deploy Edge Functions
```bash
# Token transaksi Midtrans Snap
supabase functions deploy create-transaction

# Webhook notifikasi pembayaran + role sync (tanpa JWT karena dipanggil oleh Midtrans)
supabase functions deploy payment-notification --no-verify-jwt

# Push notification via FCM
supabase functions deploy send-push --no-verify-jwt
```

### 5. Konfigurasi Webhook Midtrans
Salin URL hasil deploy `payment-notification` dan daftarkan di:
**Midtrans Dashboard → Settings → Payment Notification URL**

```
https://<project-ref>.supabase.co/functions/v1/payment-notification
```

---

## 🔐 File Sensitif (Tidak di-commit)

| File | Kenapa Sensitif |
|---|---|
| `lib/config/supabase_config.dart` | Supabase URL & Anon Key |
| `android/app/src/google-services.json` | Firebase API Key & Project ID |
| `android/local.properties` | Path SDK lokal tiap developer |
| `supabase/.temp/` | Linked project ref & org ID |
| `supabase/config.toml` | Konfigurasi Supabase CLI |
| `supabase/functions/*/index.ts` | Logic bisnis & backend |

---

## 👥 Tim Pengembangan

| GitHub | Nama | Peran |
|---|---|---|
| [@yosima050](https://github.com/yosima050) | Yosep | Lead Developer & Integrator |
| [@ayaa](https://github.com/ayaa) | Aurellia | Developer & UI Specialist |
| [@cristanti-p](https://github.com/cristanti-p) | Revalina Kristanti Putri | Developer & UI Specialist |
| [@raratii](https://github.com/raratii) | Purnama Ratih | Developer & QA |

---

© 2026 BooyahHub Project — Teknologi Informasi, Politeknik Negeri Malang.