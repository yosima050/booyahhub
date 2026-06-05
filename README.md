# 🎮 BooyahHub: E-sports Scrim & Tournament Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Powered-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Midtrans](https://img.shields.io/badge/Midtrans-Integrated-011F4B?logo=speedtest&logoColor=white)](https://midtrans.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-orange)](https://github.com/yosima050/booyahhub)

**BooyahHub** merupakan platform turnamen dan scrimmage (scrim) game mobile hybrid (khususnya untuk komunitas gamer Free Fire / e-sports) yang memisahkan peran antara **Peserta (Mobile App)** untuk pendaftaran scrim dan pembayaran real-time menggunakan Midtrans, **Admin (Web/Mobile)** untuk manajemen scrim/room, serta **Platform Owner (Web/Mobile)** untuk pengelolaan keuangan dan akun secara terpusat.

---

## 🛠️ Panduan Instalasi (Setup Guide)

Ikuti langkah-langkah di bawah ini untuk menjalankan proyek ini di lingkungan lokal Anda:

### 1. Klon Repositori
Buka terminal dan jalankan perintah berikut:
```sh
git clone https://github.com/yosima050/booyahhub.git
cd booyahhub
```

### 2. Dapatkan File Konfigurasi Rahasia (Penting!)
Demi keamanan, file konfigurasi sensitif **tidak disertakan** di dalam repositori ini. Anda wajib meminta file tersebut kepada pemilik repositori atau membuat file konfigurasi secara mandiri dengan format berikut:

* **`supabase_config.dart`**: Buat file ini dan letakkan pada direktori `lib/config/`.
  
  Format isi file:
  ```dart
  class SupabaseConfig {
    static const String url = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://YOUR_PROJECT_ID.supabase.co');
    static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
      defaultValue: 'YOUR_ANON_PUBLIC_KEY');
  }
  ```

### 3. Instal Dependensi
Jalankan perintah berikut untuk mengunduh seluruh paket dependensi yang dibutuhkan oleh aplikasi Flutter:
```bash
flutter pub get
```

### 4. Menjalankan Proyek
Aplikasi ini dapat dijalankan pada platform Android maupun Web (Chrome):

* **Mobile App (Peserta / Admin):**
  ```bash
  flutter run -d android
  ```

* **Web/Dashboard (Admin / Platform Owner):**
  ```bash
  flutter run -d chrome
  ```

---

## ⚡ Integrasi Supabase & Edge Functions (Midtrans)

Proyek ini menggunakan Supabase Edge Functions untuk mengintegrasikan pembayaran Midtrans Snap secara aman. Ikuti langkah-langkah berikut untuk melakukan deployment:

### 1. Instalasi & Login Supabase CLI
Pastikan Anda telah menginstal Supabase CLI pada perangkat lokal Anda, kemudian lakukan autentikasi:
```bash
supabase login
```

### 2. Konfigurasi Environment & Secrets di Supabase
Atur secret key Midtrans Server Key pada proyek Supabase Anda:
```bash
supabase secrets set MIDTRANS_SERVER_KEY=SB-Mid-server-xxxxx
supabase secrets set MIDTRANS_IS_PRODUCTION=false
```

### 3. Deploy Edge Functions
Jalankan perintah berikut untuk mengunggah fungsi pembuatan transaksi dan penanganan webhook pembayaran:

```bash
# Mengunggah fungsi pembuat token transaksi snap
supabase functions deploy create-transaction

# Mengunggah fungsi webhook callback notifikasi (tanpa verifikasi JWT karena dipanggil secara langsung oleh sistem Midtrans)
supabase functions deploy payment-notification --no-verify-jwt
```

### 4. Konfigurasi Webhook Midtrans
Salin URL hasil deploy `payment-notification` (contoh: `https://<project-id>.supabase.co/functions/v1/payment-notification`) dan daftarkan pada **Midtrans Dashboard** → **Settings** → **Payment Notification URL**.

---

## 🏗️ Peran Pengguna & Arsitektur
Aplikasi ini menerapkan pembagian peran (role) berbasis metadata pengguna yang dikelola melalui **Supabase Auth**:

1. **Peserta**: Mengakses halaman pendaftaran scrim, mengisi data tim, melakukan pembayaran otomatis via Midtrans Snap (WebView), memantau status pendaftaran, serta melakukan klaim hadiah.
2. **Admin**: Membuat scrim baru, mengelola data pendaftar, memperbarui ID room game, mengunggah hasil scrim, serta mengirimkan pengumuman.
3. **Platform**: Memantau dashboard keuangan pendaftaran scrim, mengelola akun admin, mengatur keanggotaan premium, serta memverifikasi klaim hadiah dari peserta.

Logika penentuan dashboard diatur pada `lib/main.dart` dengan mendeteksi properti `role` dari metadata pengguna saat aplikasi dijalankan.

---

## 👥 Tim Pengembangan (Contributors)
* **yosima050** (Yosep) - Lead Developer & Integrator
* **ayaa** (Aurellia) - Developer & UI Specialist
* **cristanti-p** (Revalina Kristanti Putri) - Developer & UI Specialist
* **raratii** (Purnama Ratih) - Developer & QA

---

© 2026 BooyahHub Project - Teknologi Informasi Politeknik Negeri Malang.