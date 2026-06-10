# 📋 SPESIFIKASI USE CASE (USE CASE SPECIFICATION)
## Platform Scrim & Tournament E-Sports (Free Fire) — BooyahHub

> **Versi Dokumen:** 2.0 (Pendamping Dokumen Resmi SKPL)  
> **Tanggal:** Juni 2026  
> **Target Sistem:** Aplikasi Mobile BooyahHub (Flutter, Supabase, Midtrans Sandbox, Firebase FCM)

---

## 📋 Daftar Isi
1. [Pendahuluan](#1-pendahuluan)
2. [Tabel Ringkasan Use Case](#2-tabel-ringkasan-use-case)
3. [Spesifikasi Use Case Detil](#3-spesifikasi-use-case-detil)
   - [UC-01: Registrasi Akun](#uc-01-registrasi-akun)
   - [UC-02: Login](#uc-02-login)
   - [UC-03: Browse & Cari Scrim](#uc-03-browse--cari-scrim)
   - [UC-04: Lihat Detail Scrim](#uc-04-lihat-detail-scrim)
   - [UC-05: Daftar Scrim](#uc-05-daftar-scrim)
   - [UC-06: Pembayaran via Midtrans](#uc-06-pembayaran-via-midtrans)
   - [UC-07: Lihat Status Pendaftaran](#uc-07-lihat-status-pendaftaran)
   - [UC-08: Terima Room ID & Password](#uc-08-terima-room-id--password)
   - [UC-09: Lihat Hasil Pertandingan](#uc-09-lihat-hasil-pertandingan)
   - [UC-10: Klaim Hadiah](#uc-10-klaim-hadiah)
   - [UC-11: Lihat Leaderboard](#uc-11-lihat-leaderboard)
   - [UC-12: Kelola Profil & Rekening Bank](#uc-12-kelola-profil--rekening-bank)
   - [UC-13: Buat Scrim Baru](#uc-13-buat-scrim-baru)
   - [UC-14: Simpan Draft](#uc-14-simpan-draft)
   - [UC-15: Kelola Pendaftaran Peserta](#uc-15-kelola-pendaftaran-peserta)
   - [UC-16: Kirim Room ID ke Peserta](#uc-16-kirim-room-id-ke-peserta)
   - [UC-17: Input Hasil Pertandingan](#uc-17-input-hasil-pertandingan)
   - [UC-18: Verifikasi Klaim Hadiah](#uc-18-verifikasi-klaim-hadiah)
   - [UC-19: Berlangganan Premium](#uc-19-berlangganan-premium)
   - [UC-20: Dashboard Keuangan](#uc-20-dashboard-keuangan)
   - [UC-21: Kelola & Suspend Pengguna](#uc-21-kelola--suspend-pengguna)
   - [UC-22: Approve/Reject Premium Request](#uc-22-approvereject-premium-request)

---

## 1. Pendahuluan
Dokumen **Spesifikasi Use Case (Use Case Specification)** ini berfungsi sebagai penjabaran tekstual mendalam dari [DOKUMENTASI.md](file:///d:/Project/booyahhub/DOKUMENTASI.md). Dokumen ini menjelaskan skenario interaksi pengguna dengan sistem secara rinci, termasuk kondisi awal (*preconditions*), kondisi akhir (*postconditions*), alur normal (*basic flow*), serta penanganan kondisi error atau cabang (*alternative/exception flows*).

---

## 2. Tabel Ringkasan Use Case

| ID Use Case | Nama Use Case | Aktor Utama | Deskripsi Singkat |
|---|---|---|---|
| **UC-01** | Registrasi Akun | Pengguna Baru | Membuat kredensial akun baru dan profil pengguna. |
| **UC-02** | Login | Peserta, Admin, Platform | Mendapatkan token JWT aktif untuk masuk ke sistem. |
| **UC-03** | Browse & Cari Scrim | Peserta | Menemukan event scrim aktif menggunakan filter atau pencarian. |
| **UC-04** | Lihat Detail Scrim | Peserta | Memeriksa informasi prasyarat, jadwal, slot, dan hadiah event. |
| **UC-05** | Daftar Scrim | Peserta | Melakukan pemesanan slot tim dengan status awal pending payment. |
| **UC-06** | Pembayaran via Midtrans | Peserta | Menyelesaikan pembayaran pendaftaran event secara online. |
| **UC-07** | Lihat Status Pendaftaran | Peserta | Memeriksa berkas registrasi, status bayar, dan Room ID. |
| **UC-08** | Terima Room ID & Password | Peserta | Memperoleh kredensial custom room Free Fire untuk bertanding. |
| **UC-09** | Lihat Hasil Pertandingan | Peserta | Memeriksa klasemen poin, penempatan, dan nominal klaim hadiah. |
| **UC-10** | Klaim Hadiah | Peserta (Pemenang) | Mengajukan pencairan dana hadiah scrim ke rekening terdaftar. |
| **UC-11** | Lihat Leaderboard | Peserta, Umum | Memantau klasemen tim secara global atau khusus event. |
| **UC-12** | Kelola Profil & Rekening Bank | Peserta | Mengubah informasi profil, avatar, dan rekening klaim. |
| **UC-13** | Buat Scrim Baru | Admin | Membuat event scrim/turnamen baru secara langsung (open). |
| **UC-14** | Simpan Draft | Admin | Menyimpan konfigurasi event tanpa mempublikasikannya langsung. |
| **UC-15** | Kelola Pendaftaran Peserta | Admin | Memantau daftar tim terdaftar dan melakukan diskualifikasi jika perlu. |
| **UC-16** | Kirim Room ID ke Peserta | Admin | Mengirimkan akses custom room secara massal melalui Firebase FCM. |
| **UC-17** | Input Hasil Pertandingan | Admin | Mengunggah perolehan poin tim (placement & kills) pasca-game. |
| **UC-18** | Verifikasi Klaim Hadiah | Admin | Meninjau pengajuan klaim hadiah dan menyetujui pasca-transfer. |
| **UC-19** | Berlangganan Premium | Admin | Membeli paket premium agar scrim buatannya menjadi unggulan. |
| **UC-20** | Dashboard Keuangan | Platform | Mengaudit arus kas masuk dan keluar di seluruh platform. |
| **UC-21** | Kelola & Suspend Pengguna | Platform | Melakukan moderasi atau penonaktifan akun bermasalah. |
| **UC-22** | Approve/Reject Premium Request | Platform | Memverifikasi dan mengaktifkan status premium berbayar admin. |

---

## 3. Spesifikasi Use Case Detil

### UC-01: Registrasi Akun
* **ID & Nama**: UC-01 Registrasi Akun
* **Aktor Utama**: Pengguna Baru (Peserta / Admin)
* **Aktor Pendukung / Sistem Eksternal**: Supabase Auth & Database
* **Deskripsi**: Use case ini memungkinkan calon pengguna baru untuk membuat kredensial akun serta profil pengguna di dalam basis data BooyahHub.
* **Kondisi Awal (Preconditions)**: Pengguna belum terdaftar di dalam sistem dan belum memiliki sesi masuk aktif.
* **Kondisi Akhir (Postconditions)**: Akun pengguna terdaftar di Supabase Auth, baris baru ditambahkan ke tabel `users` dengan peran (`role`) default `participant`, dan email konfirmasi dikirim.
* **Alur Utama (Basic Flow)**:
  1. Pengguna membuka halaman registrasi pada aplikasi mobile BooyahHub.
  2. Sistem menampilkan formulir registrasi yang terdiri dari kolom Nama Lengkap, Email, Kata Sandi, dan Konfirmasi Kata Sandi.
  3. Pengguna mengisi semua informasi yang diminta.
  4. Pengguna menekan tombol "Daftar".
  5. Sistem melakukan validasi format email dan panjang kata sandi secara lokal.
  6. Sistem memanggil fungsi Supabase Auth `signUp(email, password)`.
  7. Sistem membuat baris baru di tabel `users` dengan `role='participant'` melalui database trigger.
  8. Sistem mengirimkan tautan verifikasi ke email pengguna.
  9. Sistem menampilkan pesan pop-up meminta pengguna untuk memeriksa email masuk.
  10. Pengguna membuka email dan mengklik tautan verifikasi.
  11. Supabase Auth memverifikasi token dan mengaktifkan status autentikasi.
  12. Sistem mengarahkan pengguna kembali ke Halaman Login.
* **Alur Alternatif & Eksepsi (Alternative & Exception Flows)**:
  - **Alt-1: Validasi Format Gagal**
    - Pada langkah 5, jika format email tidak sesuai atau kata sandi terlalu pendek, sistem menampilkan pesan error validasi di bawah kolom input yang bersangkutan dan membatalkan pengiriman formulir.
  - **Alt-2: Email Duplikat**
    - Pada langkah 6, jika email yang dimasukkan sudah pernah terdaftar, Supabase Auth mengembalikan error email duplikat. Sistem menampilkan pesan error "Email sudah terdaftar" dan mengembalikan pengguna ke formulir registrasi.

---

### UC-02: Login
* **ID & Nama**: UC-02 Login
* **Aktor Utama**: Peserta, Admin, Platform
* **Aktor Pendukung / Sistem Eksternal**: Supabase Auth & Database
* **Deskripsi**: Use case ini digunakan oleh semua tipe pengguna (Peserta, Admin, Platform) untuk mendapatkan token JWT aktif sehingga dapat mengakses fitur sesuai hak akses (role) masing-masing.
* **Kondisi Awal (Preconditions)**: Pengguna memiliki akun terdaftar dan alamat email telah diverifikasi.
* **Kondisi Akhir (Postconditions)**: Pengguna mendapatkan sesi JWT aktif, data waktu masuk diperbarui, dan dialihkan ke dashboard yang sesuai.
* **Alur Utama (Basic Flow)**:
  1. Pengguna membuka aplikasi mobile BooyahHub pada halaman Login.
  2. Sistem menampilkan formulir isian Email dan Kata Sandi.
  3. Pengguna memasukkan kredensial login.
  4. Pengguna menekan tombol "Login".
  5. Sistem memanggil API Supabase Auth `signInWithPassword(email, password)`.
  6. Supabase memverifikasi kecocokan kredensial dan mengembalikan informasi sesi (termasuk `access_token` dan `user.id`).
  7. Sistem mengambil data detail profil pengguna dari tabel `users` berdasarkan UUID yang masuk.
  8. Sistem memverifikasi bahwa akun tersebut tidak ditangguhkan (`is_suspended = false`).
  9. Sistem memperbarui data waktu masuk terakhir (`last_login_at`) pada database.
  10. Sistem merender menu utama / dashboard aplikasi sesuai peran pengguna (`participant` dialihkan ke Home, `admin` dialihkan ke Admin Dashboard, dan `platform` dialihkan ke Platform Dashboard).
* **Alur Alternatif & Eksepsi (Alternative & Exception Flows)**:
  - **Alt-1: Form Isian Kosong**
    - Pada langkah 3, jika salah satu atau kedua kolom input kosong, tombol Login dinonaktifkan atau sistem menampilkan pesan "Kredensial wajib diisi".
  - **Alt-2: Kredensial Tidak Cocok**
    - Pada langkah 5, jika kombinasi email dan kata sandi salah, Supabase Auth mengembalikan error. Sistem menampilkan pesan error "Email atau password salah" dan mengosongkan kolom input kata sandi.
  - **Alt-3: Akun Ditangguhkan (Suspended)**
    - Pada langkah 8, jika status pengguna menunjukkan `is_suspended = true`, sistem secara otomatis memanggil fungsi `signOut()`, menampilkan dialog peringatan "Akun Anda disuspend: [alasan]", dan membatalkan proses masuk.

---

### UC-03: Browse & Cari Scrim
* **ID & Nama**: UC-03 Browse & Cari Scrim
* **Aktor Utama**: Peserta
* **Aktor Pendukung / Sistem Eksternal**: Supabase Database (View `v_scrim_list`)
* **Deskripsi**: Use case ini memungkinkan peserta untuk mencari event scrim yang aktif berdasarkan filter atau kata kunci tertentu untuk diikuti.
* **Kondisi Awal (Preconditions)**: Peserta telah login dan berada di halaman utama aplikasi.
* **Kondisi Akhir (Postconditions)**: Peserta melihat daftar scrim yang sesuai dengan filter atau kata kunci pencarian.
* **Alur Utama (Basic Flow)**:
  1. Peserta membuka tab "Beranda" atau menu "Browse".
  2. Sistem melakukan query ke basis data menggunakan perintah `SELECT * FROM v_scrim_list WHERE status='open' ORDER BY is_featured DESC, scheduled_at ASC`.
  3. Sistem menampilkan daftar kartu event scrim di layar.
* **Alur Alternatif & Eksepsi (Alternative & Exception Flows)**:
  - **Alt-1: Penggunaan Fitur Filter**
    - Pada langkah 2, peserta dapat menekan tombol filter dan memilih kategori (Mode Game: Solo/Duo/Squad, Server, atau Batas Biaya Registrasi).
    - Sistem melakukan query database ulang berdasarkan parameter terpilih dan memperbarui antarmuka pengguna dengan daftar scrim terfilter.
  - **Alt-2: Penggunaan Kolom Pencarian**
    - Pada langkah 2, peserta mengetikkan kata kunci pada kolom pencarian.
    - Sistem melakukan pencarian menggunakan pola string (`ILIKE '%keyword%'`) pada kolom judul scrim.
    - Jika data ditemukan, sistem menampilkan scrim yang relevan. Jika tidak ditemukan, sistem menampilkan pesan "Scrim tidak ditemukan".

---

### UC-04: Lihat Detail Scrim
* **ID & Nama**: UC-04 Lihat Detail Scrim
* **Aktor Utama**: Peserta
* **Aktor Pendukung / Sistem Eksternal**: Supabase Database
* **Deskripsi**: Use case ini memberikan rincian lengkap mengenai suatu event scrim, meliputi informasi penyelenggara, waktu pelaksanaan, sisa kuota slot, biaya masuk, dan nominal prize pool sebelum peserta mendaftar.
* **Kondisi Awal (Preconditions)**: Peserta telah membuka halaman utama dan memilih salah satu scrim.
* **Kondisi Akhir (Postconditions)**: Detail scrim ditampilkan dengan tombol aksi pendaftaran yang menyesuaikan status event.
* **Alur Utama (Basic Flow)**:
  1. Peserta memilih salah satu kartu scrim pada daftar scrim.
  2. Sistem melakukan query SELECT terhadap tabel `scrims` digabungkan (JOIN) dengan `admin_profiles` berdasarkan ID scrim terpilih.
  3. Sistem mengambil informasi slot terisi (`slot_filled`) dan batas waktu pendaftaran (`registration_closes_at`).
  4. Sistem memverifikasi ketersediaan slot (`slot_filled < slot_total`) dan batas waktu pendaftaran (`registration_closes_at > sekarang`).
  5. Sistem menampilkan halaman detail scrim lengkap dengan deskripsi, tombol "Daftar Sekarang" diaktifkan.
* **Alur Alternatif & Eksepsi (Alternative & Exception Flows)**:
  - **Alt-1: Slot Penuh atau Waktu Pendaftaran Habis**
    - Pada langkah 4, jika slot penuh atau waktu pendaftaran telah berakhir, sistem menonaktifkan tombol "Daftar Sekarang" dan menggantinya dengan informasi bertuliskan "Pendaftaran Ditutup" atau "Slot Penuh".

---

### UC-05: Daftar Scrim
* **ID & Nama**: UC-05 Daftar Scrim
* **Aktor Utama**: Peserta
* **Aktor Pendukung / Sistem Eksternal**: Supabase Database
* **Deskripsi**: Use case ini memungkinkan peserta untuk mengunci slot pendaftaran sementara dengan mengisi data tim dan anggota tim sebelum melakukan pembayaran.
* **Kondisi Awal (Preconditions)**: Event scrim berstatus `open`, slot kuota masih tersedia, dan batas waktu pendaftaran belum terlewati.
* **Kondisi Akhir (Postconditions)**: Baris pendaftaran baru tersimpan di tabel `registrations` dengan status awal `pending_payment` dan detail anggota tim tersimpan di tabel `team_members`.
* **Alur Utama (Basic Flow)**:
  1. Peserta menekan tombol "Daftar Sekarang" pada Halaman Detail Scrim.
  2. Sistem menampilkan formulir pendaftaran.
  3. Peserta memasukkan Nama Tim dan Nomor Handphone Kapten Tim yang aktif.
  4. Peserta memasukkan data Free Fire ID (FF ID) untuk setiap anggota tim sesuai kebutuhan mode scrim (contoh: 4 ID untuk mode Squad).
  5. Peserta menekan tombol "Lanjut Pembayaran".
  6. Sistem mengevaluasi kembali sisa slot scrim secara waktu nyata.
  7. Sistem menyisipkan baris pendaftaran baru ke tabel `registrations` dengan status `pending_payment`.
  8. Sistem menyimpan daftar FF ID anggota ke tabel `team_members`.
  9. Sistem mengalihkan alur ke Modul Pembayaran (UC-06).
* **Alur Alternatif & Eksepsi (Alternative & Exception Flows)**:
  - **Alt-1: Slot Terisi Penuh Di Detik Terakhir**
    - Pada langkah 6, jika slot ternyata baru saja penuh diisi oleh tim lain sesaat sebelum menekan tombol pembayaran, sistem membatalkan proses pendaftaran dan menampilkan dialog "Maaf, slot scrim baru saja penuh".

---

### UC-06: Pembayaran via Midtrans
* **ID & Nama**: UC-06 Pembayaran via Midtrans
* **Aktor Utama**: Peserta
* **Aktor Pendukung / Sistem Eksternal**: Supabase Edge Functions, Midtrans Sandbox API, Firebase FCM Service
* **Deskripsi**: Use case ini memproses transaksi pembayaran biaya registrasi secara online melalui gateway pembayaran Midtrans Sandbox.
* **Kondisi Awal (Preconditions)**: Data pendaftaran tersimpan dengan status `pending_payment` (dari UC-05).
* **Kondisi Akhir (Postconditions)**: Pembayaran sukses terverifikasi, status pendaftaran berubah menjadi `verified`, jumlah slot terisi diupdate, dan log transaksi tersimpan.
* **Alur Utama (Basic Flow)**:
  1. Sistem memanggil Supabase Edge Function `/create-transaction` dengan membawa ID registrasi.
  2. Edge Function memproses payload transaksi dan meminta token transaksi ke Midtrans Snap API.
  3. Midtrans API mengembalikan `snap_token` beserta URL pembayaran.
  4. Edge Function menyimpan `midtrans_snap_token` ke dalam data registrasi bersangkutan di database.
  5. Aplikasi membuka Webview Midtrans Snap di dalam aplikasi.
  6. Peserta memilih metode pembayaran (misal virtual account, e-wallet) dan menyelesaikan transaksi pembayaran pada emulator Sandbox Midtrans.
  7. Midtrans memproses transaksi dan mengirimkan webhook HTTP POST callback ke Edge Function `/payment-notification`.
  8. Edge Function memverifikasi keabsahan signature kunci SHA-512 dari Midtrans.
  9. Setelah tervalidasi, sistem melakukan UPDATE status registrasi menjadi `verified` dan memperbarui data status transaksi Midtrans menjadi `settlement`.
  10. Sistem menambahkan jumlah slot terisi (`slot_filled = slot_filled + 1`) pada tabel `scrims`.
  11. Sistem mencatat baris baru ke tabel `transactions` dengan tipe `registration_fee`.
  12. Firebase FCM Service mengirimkan push notifikasi ke perangkat peserta yang menginformasikan bahwa pembayaran berhasil dikonfirmasi.
  13. Aplikasi mobile yang berlangganan perubahan status real-time memuat ulang layar dan menampilkan pesan sukses.
* **Alur Alternatif & Eksepsi (Alternative & Exception Flows)**:
  - **Alt-1: Peserta Membatalkan Pembayaran (Cancel)**
    - Pada langkah 6, jika peserta menutup halaman Webview Midtrans Snap tanpa menyelesaikan pembayaran, sistem memperbarui status registrasi menjadi `failed`/`cancelled` dan mengembalikan peserta ke halaman beranda.
  - **Alt-2: Tanda Tangan Webhook Tidak Valid**
    - Pada langkah 8, jika signature key yang dikirimkan oleh webhook tidak cocok dengan perhitungan SHA-512 lokal, sistem menolak memperbarui database dan mengirimkan respon HTTP 401 Unauthorized ke Midtrans.

---

### UC-07: Lihat Status Pendaftaran
* **ID & Nama**: UC-07 Lihat Status Pendaftaran
* **Aktor Utama**: Peserta
* **Aktor Pendukung / Sistem Eksternal**: Supabase Database
* **Deskripsi**: Use case ini digunakan oleh peserta untuk memeriksa detail data pendaftaran tim, memantau status verifikasi pembayaran, serta memantau rincian Room ID pasca-pendaftaran.
* **Kondisi Awal (Preconditions)**: Peserta telah melakukan registrasi scrim setidaknya satu kali.
* **Kondisi Akhir (Postconditions)**: Rincian berkas registrasi beserta lencana status ditampilkan di layar peserta.
* **Alur Utama (Basic Flow)**:
  1. Peserta membuka menu "Riwayat Scrim" atau "Status".
  2. Sistem memuat daftar data registrasi milik pengguna bersangkutan dari tabel `registrations`.
  3. Peserta mengklik salah satu data pendaftaran untuk melihat detailnya.
  4. Sistem mengambil data status pembayaran terbaru dan ketersediaan Room ID.
  5. Sistem menampilkan detail tim, data anggota, lencana status (`pending_payment`, `verified`, atau `failed`/`expired`).
* **Alur Alternatif & Eksepsi (Alternative & Exception Flows)**:
  - **Alt-1: Pendaftaran Masih Pending**
    - Jika status pendaftaran masih `pending_payment`, sistem menampilkan tombol "Bayar Sekarang". Jika diklik, sistem membuka kembali modul pembayaran Midtrans (UC-06).
  - **Alt-2: Pendaftaran Sukses Terverifikasi**
    - Jika status pendaftaran adalah `verified`, sistem mengaktifkan area informasi "Room ID & Password" untuk memantau detail akses game.

---

### UC-08: Terima Room ID & Password
* **ID & Nama**: UC-08 Terima Room ID & Password
* **Aktor Utama**: Peserta
* **Aktor Pendukung / Sistem Eksternal**: Admin, Firebase FCM Service, Supabase Database
* **Deskripsi**: Use case ini memfasilitasi penyerahan informasi rahasia berupa ID Room dan Password Custom Room Free Fire kepada seluruh peserta yang pendaftarannya berstatus terverifikasi.
* **Kondisi Awal (Preconditions)**: Status pendaftaran tim peserta adalah `verified` dan admin telah melakukan distribusi Room ID.
* **Kondisi Akhir (Postconditions)**: Peserta berhasil menyalin kredensial Room ID dan masuk ke dalam kustom room permainan Free Fire.
* **Alur Utama (Basic Flow)**:
  1. Admin menginput detail Room ID dan Password di Dashboard Admin (memicu notifikasi FCM).
  2. Peserta menerima pemberitahuan push "Room ID Telah Dikirim" di perangkat selulernya.
  3. Peserta menekan push notifikasi atau membuka halaman status detail scrim terkait.
  4. Sistem melakukan query ke tabel `scrims` untuk membaca field `room_id` dan `room_password`.
  5. Sistem menampilkan dialog pop-up yang menyajikan Room ID dan Password secara terpisah, lengkap dengan tombol "Salin" untuk masing-masing kredensial.
  6. Peserta menyalin kredensial tersebut, lalu membuka game Free Fire untuk masuk ke Custom Room.

---

### UC-09: Lihat Hasil Pertandingan
* **ID & Nama**: UC-09 Lihat Hasil Pertandingan
* **Aktor Utama**: Peserta
* **Aktor Pendukung / Sistem Eksternal**: Supabase Database
* **Deskripsi**: Use case ini memungkinkan peserta untuk melihat klasemen akhir pertandingan, rincian perolehan poin tim, serta jumlah hadiah yang berhak didapatkan pasca event selesai.
* **Kondisi Awal (Preconditions)**: Scrim memiliki status `finished` dan data klasemen akhir telah dimasukkan oleh admin.
* **Kondisi Akhir (Postconditions)**: Informasi peringkat tim dan tombol pengajuan klaim hadiah ditampilkan di layar.
* **Alur Utama (Basic Flow)**:
  1. Peserta membuka Halaman Detail Scrim yang telah selesai.
  2. Peserta mengklik tab "Hasil Pertandingan" / "Klasemen".
  3. Sistem mengambil data dari tabel `match_results` berdasarkan ID scrim terkait, diurutkan dengan `rank ASC`.
  4. Sistem menampilkan tabel peringkat tim lengkap dengan jumlah kill, poin penempatan (placement), total poin, dan besaran hadiah yang diperoleh.
  5. Sistem mendeteksi apakah tim peserta masuk dalam jajaran pemenang hadiah (`prize_amount > 0`).
  6. Sistem mendeteksi bahwa tim peserta berhak mengklaim hadiah dan mengaktifkan tombol "Klaim Hadiah".
* **Alur Alternatif & Eksepsi (Alternative & Exception Flows)**:
  - **Alt-1: Tim Peserta Tidak Menang Hadiah**
    - Pada langkah 5, jika nilai `prize_amount` tim adalah `0`, sistem tidak menampilkan banner ucapan selamat dan menonaktifkan atau menyembunyikan tombol "Klaim Hadiah".

---

### UC-10: Klaim Hadiah
* **ID & Nama**: UC-10 Klaim Hadiah
* **Aktor Utama**: Peserta (Pemenang)
* **Aktor Pendukung / Sistem Eksternal**: Supabase Database, Firebase FCM Service
* **Deskripsi**: Use case ini digunakan oleh kapten tim pemenang untuk mengajukan pencairan dana hadiah event ke rekening bank mereka.
* **Kondisi Awal (Preconditions)**: Event scrim berstatus `finished`, tim terdaftar sebagai pemenang dengan `prize_amount > 0`, dan status klaim belum pernah diajukan.
* **Kondisi Akhir (Postconditions)**: Baris klaim baru dengan status `pending` ditambahkan ke tabel `prize_claims`, notifikasi terkirim ke admin scrim.
* **Alur Utama (Basic Flow)**:
  1. Peserta menekan tombol "Klaim Hadiah" pada menu Hasil Pertandingan.
  2. Sistem mencari rekening bank terdaftar milik pengguna dari tabel `bank_accounts`.
  3. Sistem menampilkan formulir pengajuan klaim yang berisi pilihan rekening bank aktif.
  4. Peserta memilih salah satu rekening utama dan menekan tombol "Kirim Pengajuan Klaim".
  5. Sistem menyisipkan baris klaim baru ke tabel `prize_claims` dengan status `pending` dan nominal dana sesuai hadiah.
  6. Sistem mengirimkan notifikasi pemberitahuan adanya klaim baru ke admin pembuat scrim.
  7. Sistem menampilkan status klaim menjadi "Menunggu Verifikasi Admin".
* **Alur Alternatif & Eksepsi (Alternative & Exception Flows)**:
  - **Alt-1: Rekening Belum Terdaftar**
    - Pada langkah 2, jika sistem mendeteksi belum ada rekening terdaftar, sistem menampilkan opsi pengisian rekening baru.
    - Peserta mengisi Nama Bank, Nomor Rekening, dan Nama Pemilik Rekening, lalu menekan tombol simpan.
    - Sistem menyimpan rekening tersebut ke tabel `bank_accounts` dengan status `is_primary = true`, lalu mengarahkan kembali ke langkah 3.

---

### UC-11: Lihat Leaderboard
* **ID & Nama**: UC-11 Lihat Leaderboard
* **Aktor Utama**: Peserta, Umum (Pengguna tanpa login)
* **Aktor Pendukung / Sistem Eksternal**: Supabase Database & Realtime Engine
* **Deskripsi**: Use case ini memungkinkan semua pengguna untuk memantau akumulasi klasemen performa tim secara global atau detail per event scrim secara waktu nyata.
* **Kondisi Awal (Preconditions)**: Pengguna membuka aplikasi dan masuk ke menu Leaderboard.
* **Kondisi Akhir (Postconditions)**: Klasemen tim ditampilkan dan diperbarui secara otomatis ketika terjadi pembaruan data di server.
* **Alur Utama (Basic Flow)**:
  1. Pengguna menekan menu "Leaderboard" pada navigasi utama.
  2. Sistem memuat daftar scrim yang tersedia dari tabel `scrims`.
  3. Sistem merender dua tab pilihan: "Scrim Saya" (hanya aktif jika pengguna telah login) dan "Scrim Umum" (untuk semua pengguna).
  4. Pengguna memilih salah satu judul scrim dari daftar event.
  5. Sistem memuat view database `v_leaderboard` untuk scrim terpilih.
  6. Sistem menampilkan klasemen detail meliputi logo tim, nama tim, podium juara (1, 2, 3), total poin, dan detail kill.
  7. Sistem mendaftarkan koneksi (subscribe) ke channel real-time Supabase untuk tabel `match_results` scrim tersebut.
  8. Apabila admin memperbarui hasil, sistem mendeteksi perubahan data dan langsung memperbarui tampilan klasemen di layar secara real-time tanpa perlu refresh manual.
* **Alur Alternatif & Eksepsi (Alternative & Exception Flows)**:
  - **Alt-1: Pengguna Belum Login**
    - Pada langkah 3, jika pengguna belum melakukan autentikasi login, tab "Scrim Saya" dinonaktifkan atau diarahkan untuk login terlebih dahulu.

---

### UC-12: Kelola Profil & Rekening Bank
* **ID & Nama**: UC-12 Kelola Profil & Rekening Bank
* **Aktor Utama**: Peserta
* **Aktor Pendukung / Sistem Eksternal**: Supabase Storage, Supabase Database, Supabase Auth
* **Deskripsi**: Use case ini memfasilitasi pengubahan informasi biodata profil pengguna, penggantian gambar avatar, pengelolaan nomor rekening bank pribadi, serta pengubahan kata sandi akun.
* **Kondisi Awal (Preconditions)**: Pengguna telah login ke sistem.
* **Kondisi Akhir (Postconditions)**: Data profil, foto profil, daftar rekening bank, atau kata sandi diperbarui di database.
* **Alur Utama (Basic Flow)**:
  1. Pengguna membuka halaman "Pengaturan Profil" atau "Akun".
  2. Sistem memanggil data pengguna dari tabel `users` dan daftar rekening bank dari tabel `bank_accounts`.
  3. Sistem merender form kelola profil di layar.
  4. Pengguna dapat memilih salah satu dari 4 opsi modifikasi berikut:
     - **Opsi A: Ubah Info Biodata**
       - Pengguna mengubah Nama, Username, atau Free Fire ID, lalu menekan tombol "Simpan".
       - Sistem melakukan query UPDATE ke tabel `users`.
     - **Opsi B: Ganti Foto Profil**
       - Pengguna mengklik avatar dan memilih foto baru dari galeri ponsel.
       - Sistem mengunggah berkas gambar tersebut ke Supabase Storage bucket `avatars`.
       - Sistem memperbarui kolom `avatar_url` pada tabel `users` dengan URL publik gambar baru.
     - **Opsi C: Kelola Rekening Bank**
       - Pengguna memasukkan data rekening baru (Bank, No. Rekening, Nama Pemilik) dan menekan "Tambah Rekening".
       - Sistem menyimpan data tersebut ke tabel `bank_accounts`.
     - **Opsi D: Ganti Kata Sandi**
       - Pengguna memasukkan kata sandi lama dan baru, kemudian menekan "Perbarui Password".
       - Sistem memanggil API Supabase Auth `updateUser(password)`.
  5. Sistem menampilkan notifikasi "Pembaruan Berhasil".

---

### UC-13: Buat Scrim Baru
* **ID & Nama**: UC-13 Buat Scrim Baru
* **Aktor Utama**: Admin
* **Aktor Pendukung / Sistem Eksternal**: Supabase Database
* **Deskripsi**: Use case ini memungkinkan admin (penyelenggara) untuk membuat event scrim latihan atau turnamen baru agar dapat dipublikasikan dan menerima pendaftaran peserta.
* **Kondisi Awal (Preconditions)**: Pengguna masuk dengan peran `admin` dan status akun aktif (tidak tersuspend).
* **Kondisi Akhir (Postconditions)**: Event scrim baru berstatus `open` ditambahkan ke tabel `scrims` dan tampil di beranda peserta.
* **Alur Utama (Basic Flow)**:
  1. Admin masuk ke Dashboard Admin dan memilih tombol "Buat Scrim".
  2. Sistem menampilkan formulir pembuatan event kosong.
  3. Admin mengisi rincian event: Judul Scrim, Deskripsi, Mode Game (Solo/Duo/Squad), Server/Negara, Jadwal Waktu Pelaksanaan, Batas Waktu Pendaftaran, Kuota Slot Maksimum, Biaya Registrasi, dan Nominal Hadiah (Prize Pool).
  4. Admin menekan tombol "Publikasikan Scrim".
  5. Sistem memvalidasi parameter input (contoh: waktu registrasi harus sebelum pelaksanaan, slot harus lebih dari 0, biaya registrasi tidak boleh negatif).
  6. Sistem mengambil `admin_id` dari sesi login.
  7. Sistem melakukan operasi INSERT data ke tabel `scrims` dengan status awal `open` dan jumlah slot terisi `slot_filled = 0`.
  8. Sistem menampilkan notifikasi sukses dan mengalihkan kembali ke Dashboard Admin.
* **Alur Alternatif & Eksepsi (Alternative & Exception Flows)**:
  - **Alt-1: Validasi Input Gagal**
    - Pada langkah 5, jika terdapat ketidaksesuaian input (misalnya nominal prize pool bernilai negatif), sistem menampilkan pesan kesalahan di sebelah field input yang bersangkutan dan membatalkan proses publikasi.

---

### UC-14: Simpan Draft
* **ID & Nama**: UC-14 Simpan Draft
* **Aktor Utama**: Admin
* **Aktor Pendukung / Sistem Eksternal**: Supabase Database
* **Deskripsi**: Use case ini digunakan oleh admin untuk menyimpan draf rancangan event scrim yang belum selesai dikonfigurasi, agar tidak dipublikasikan ke publik terlebih dahulu.
* **Kondisi Awal (Preconditions)**: Pengguna memiliki akun dengan peran `admin`.
* **Kondisi Akhir (Postconditions)**: Baris event tersimpan di tabel `scrims` dengan status `draft`.
* **Alur Utama (Basic Flow)**:
  1. Admin membuka formulir pembuatan scrim baru dan menginputkan sebagian informasi event.
  2. Admin menekan tombol "Simpan Sebagai Draft".
  3. Sistem menyisipkan atau memperbarui baris data di tabel `scrims` dengan nilai status diatur sebagai `draft` dan mengaitkannya dengan `admin_id`.
  4. Sistem menampilkan pesan konfirmasi "Draf berhasil disimpan".
  5. Admin dapat mengakses draf tersebut kapan saja melalui menu penyaringan "Draft" di dashboard admin untuk melengkapi data dan mempublikasikannya.

---

### UC-15: Kelola Pendaftaran Peserta
* **ID & Nama**: UC-15 Kelola Pendaftaran Peserta
* **Aktor Utama**: Admin
* **Aktor Pendukung / Sistem Eksternal**: Supabase Database, Firebase FCM Service
* **Deskripsi**: Use case ini digunakan oleh admin untuk memantau detail pendaftaran tim peserta, memeriksa status pembayaran, serta mengambil tindakan moderasi seperti diskualifikasi peserta.
* **Kondisi Awal (Preconditions)**: Admin memiliki minimal satu event scrim aktif yang telah dipublikasikan dan memiliki pendaftar.
* **Kondisi Akhir (Postconditions)**: Status pendaftaran peserta diupdate di database, sisa kuota disesuaikan jika terjadi pembatalan.
* **Alur Utama (Basic Flow)**:
  1. Admin membuka menu detail scrim di Dashboard Admin.
  2. Admin menekan menu "Kelola Peserta" atau "Daftar Pendaftar".
  3. Sistem mengambil data registrasi (`registrations`) bergabung dengan data anggota tim (`team_members`) berdasarkan ID scrim tersebut.
  4. Sistem menyajikan daftar tim berdasarkan kategori status pendaftaran (seperti: Verified, Pending Payment, Cancelled).
  5. Admin memeriksa nama tim, nomor kontak, serta FF ID anggota tim untuk memastikan tidak ada data palsu.
* **Alur Alternatif & Eksepsi (Alternative & Exception Flows)**:
  - **Alt-1: Melakukan Diskualifikasi / Penolakan Pendaftaran**
    - Pada langkah 5, admin berhak membatalkan keikutsertaan tim dengan mengklik tombol "Reject / Diskualifikasi" pada tim terkait.
    - Sistem menampilkan input box alasan penolakan.
    - Admin mengisi alasan dan mengklik kirim.
    - Sistem mengubah status pendaftaran menjadi `rejected` / `cancelled` pada tabel `registrations`.
    - Sistem mengurangi jumlah slot terisi (`slot_filled = slot_filled - 1`) pada tabel `scrims`.
    - Firebase FCM mengirimkan push notifikasi pembatalan ke perangkat seluler kapten tim yang bersangkutan.

---

### UC-16: Kirim Room ID ke Peserta
* **ID & Nama**: UC-16 Kirim Room ID ke Peserta
* **Aktor Utama**: Admin
* **Aktor Pendukung / Sistem Eksternal**: Supabase Database, Firebase FCM Service
* **Deskripsi**: Use case ini memungkinkan admin mengirimkan informasi ID Room dan Password Custom Room Free Fire secara serentak ke perangkat seluruh peserta yang pendaftarannya berstatus verified.
* **Kondisi Awal (Preconditions)**: Event scrim berstatus `open`, kuota telah terpenuhi atau pendaftaran telah ditutup.
* **Kondisi Akhir (Postconditions)**: Kredensial Room ID dan Password tersimpan di tabel `scrims`, baris pemberitahuan disimpan ke tabel `notifications`, dan push notifikasi terkirim via FCM.
* **Alur Utama (Basic Flow)**:
  1. Admin masuk ke Dashboard Admin dan memilih salah satu scrim aktif.
  2. Admin memilih tombol "Kirim Room ID".
  3. Sistem menampilkan formulir penginputan Room ID dan Room Password.
  4. Admin menginputkan Room ID dan Password kustom room Free Fire yang telah dibuat.
  5. Admin menekan tombol "Kirim Massal".
  6. Sistem memperbarui data scrim terkait (`room_id`, `room_password`, `room_sent_at = now()`) di database.
  7. Sistem mencari daftar token FCM milik semua peserta yang status pendaftarannya bernilai `verified`.
  8. Sistem melakukan operasi batch insert untuk menyimpan record pemberitahuan ke tabel `notifications`.
  9. Sistem mengirimkan multicast push notifikasi FCM "Room ID Telah Dikirim" ke seluruh perangkat peserta verified.
  10. Sistem menampilkan pesan sukses di dashboard admin.

---

### UC-17: Input Hasil Pertandingan
* **ID & Nama**: UC-17 Input Hasil Pertandingan
* **Aktor Utama**: Admin
* **Aktor Pendukung / Sistem Eksternal**: Supabase Database (Trigger/RPC), Firebase FCM Service
* **Deskripsi**: Use case ini digunakan oleh admin untuk memasukkan data hasil akhir permainan (peringkat dan kills) guna menghitung klasemen akhir dan distribusi hadiah secara otomatis.
* **Kondisi Awal (Preconditions)**: Status event scrim adalah `ongoing` atau `open` dan pertandingan kustom room telah selesai.
* **Kondisi Akhir (Postconditions)**: Data tersimpan di tabel `match_results`, status scrim berubah menjadi `finished`, dan notifikasi dikirimkan ke peserta.
* **Alur Utama (Basic Flow)**:
  1. Admin masuk ke Dashboard Admin dan memilih menu "Input Hasil Pertandingan" pada scrim yang dituju.
  2. Sistem menampilkan daftar tim terverifikasi yang bertanding.
  3. Admin memasukkan peringkat penempatan (placement rank) dan jumlah kill untuk masing-masing tim.
  4. Sistem secara otomatis menghitung total poin (`total_point = placement_point + kills`).
  5. Admin menekan tombol "Simpan & Selesaikan Scrim".
  6. Sistem memproses urutan peringkat akhir tim secara menurun berdasarkan `total_point`.
  7. Sistem menghitung besaran nominal hadiah (`prize_amount`) berdasarkan susunan aturan hadiah scrim.
  8. Sistem melakukan operasi UPSERT ke tabel `match_results`.
  9. Sistem memperbarui status scrim menjadi `finished`.
  10. Firebase FCM mengirimkan push notifikasi massal "Hasil Klasemen Scrim Diumumkan!" ke seluruh peserta.
  11. Sistem menampilkan dialog sukses di layar admin.

---

### UC-18: Verifikasi Klaim Hadiah
* **ID & Nama**: UC-18 Verifikasi Klaim Hadiah
* **Aktor Utama**: Admin
* **Aktor Pendukung / Sistem Eksternal**: Supabase Database, Firebase FCM Service
* **Deskripsi**: Use case ini digunakan oleh admin untuk memeriksa pengajuan pencairan hadiah pemenang dan memperbarui status klaim setelah menyelesaikan transfer bank secara manual.
* **Kondisi Awal (Preconditions)**: Terdapat permintaan klaim hadiah masuk (`prize_claims`) dengan status `pending` pada event scrim milik admin tersebut.
* **Kondisi Akhir (Postconditions)**: Status pengajuan klaim hadiah diperbarui, log pencairan tersimpan di tabel transaksi, dan notifikasi konfirmasi dikirim ke pemenang.
* **Alur Utama (Basic Flow)**:
  1. Admin membuka Dashboard Admin dan memilih menu "Verifikasi Klaim".
  2. Sistem menampilkan antrean pengajuan klaim berstatus `pending`.
  3. Admin memilih salah satu pengajuan untuk melihat detail data pemenang dan detail rekening bank (Bank, No. Rekening, Nama Pemilik, Nominal Hadiah).
  4. Admin melakukan transfer dana secara manual menggunakan aplikasi M-Banking atau ATM ke rekening bank milik pemenang.
  5. Setelah transfer berhasil diselesaikan, admin mengklik tombol "Approve / Setujui".
  6. Sistem mengubah status `prize_claims` menjadi `paid`.
  7. Sistem menyisipkan baris transaksi pengeluaran baru ke tabel `transactions` dengan tipe `prize_payout` (bernilai negatif).
  8. Firebase FCM mengirimkan push notifikasi ke pemenang bahwa dana hadiah telah ditransfer.
  9. Sistem memperbarui tampilan daftar klaim di dashboard admin.
* **Alur Alternatif & Eksepsi (Alternative & Exception Flows)**:
  - **Alt-1: Pengajuan Ditolak / Reject**
    - Pada langkah 5, jika admin mendeteksi ketidaksesuaian data rekening atau kecurangan, admin mengklik tombol "Reject / Tolak".
    - Sistem menampilkan input box alasan penolakan.
    - Admin menginputkan alasan dan menekan tombol konfirmasi.
    - Sistem memperbarui status klaim menjadi `rejected` dan mencatat alasannya.
    - Firebase FCM mengirimkan push notifikasi penolakan klaim ke perangkat pemenang.

---

### UC-19: Berlangganan Premium
* **ID & Nama**: UC-19 Berlangganan Premium
* **Aktor Utama**: Admin
* **Aktor Pendukung / Sistem Eksternal**: Supabase Edge Functions, Midtrans Sandbox API, Platform Owner
* **Deskripsi**: Use case ini memungkinkan admin untuk meningkatkan akunnya menjadi premium agar event scrim buatannya bisa ditandai sebagai unggulan (*featured*) di halaman utama peserta.
* **Kondisi Awal (Preconditions)**: Admin telah login ke aplikasi dan membuka menu Berlangganan Premium.
* **Kondisi Akhir (Postconditions)**: Permintaan premium tercatat berstatus `paid` dan diajukan ke platform owner untuk aktivasi.
* **Alur Utama (Basic Flow)**:
  1. Admin membuka menu "Langganan Premium".
  2. Sistem memuat daftar paket beserta harga langganan premium dari database.
  3. Admin memilih paket langganan dan mengklik tombol "Bayar Sekarang".
  4. Sistem menyimpan record pengajuan baru ke tabel `premium_requests` dengan status awal `pending`.
  5. Sistem memanggil Edge Function `/create-transaction` dengan parameter tipe premium.
  6. Edge Function mengambil token pembayaran dari Midtrans Snap API.
  7. Aplikasi menampilkan halaman pembayaran Midtrans Snap UI (Webview).
  8. Admin menyelesaikan pembayaran di gateway Sandbox Midtrans.
  9. Midtrans mengirimkan webhook callback `settlement` ke Edge Function `/payment-notification`.
  10. Sistem memperbarui status `premium_requests` menjadi `paid`.
  11. Firebase FCM mengirimkan notifikasi pemberitahuan otomatis ke Platform Owner untuk meminta persetujuan aktivasi.
* **Alur Alternatif & Eksepsi (Alternative & Exception Flows)**:
  - **Alt-1: Pembayaran Premium Gagal / Expired**
    - Jika pembayaran tidak diselesaikan sebelum batas waktu berakhir, Midtrans mengirim callback kegagalan. Sistem memperbarui status pengajuan menjadi `failed` dan tidak memicu notifikasi ke Platform Owner.

---

### UC-20: Dashboard Keuangan
* **ID & Nama**: UC-20 Dashboard Keuangan
* **Aktor Utama**: Platform (Platform Owner)
* **Aktor Pendukung / Sistem Eksternal**: Supabase Database (View `v_platform_finance`)
* **Deskripsi**: Use case ini menyediakan ringkasan keuangan dan analisis arus kas platform secara menyeluruh untuk membantu Platform Owner mengaudit arus dana masuk dan keluar.
* **Kondisi Awal (Preconditions)**: Pengguna login sebagai akun dengan peran `platform`.
* **Kondisi Akhir (Postconditions)**: Layar menampilkan rangkuman keuangan platform secara rinci beserta grafik riwayat transaksi.
* **Alur Utama (Basic Flow)**:
  1. Platform Owner membuka menu "Dashboard Keuangan" pada aplikasi.
  2. Sistem memanggil data finansial agregat dari view `v_platform_finance`.
  3. Sistem menampilkan data: Total Pendapatan Kotor, Total Potongan Biaya Platform (Fee Platform), Total Pengeluaran Hadiah (Payouts), dan Saldo Bersih Platform.
  4. Sistem memanggil riwayat transaksi lengkap dari tabel `transactions`.
  5. Sistem merender grafik tren keuangan bulanan dan tabel daftar mutasi kas masuk/keluar.
* **Alur Alternatif & Eksepsi (Alternative & Exception Flows)**:
  - **Alt-1: Penggunaan Filter Dashboard**
    - Platform Owner memilih filter rentang tanggal (harian, mingguan, bulanan) atau filter jenis transaksi (pendaftaran, payout, premium).
    - Sistem mengeksekusi ulang query dan memperbarui grafik visualisasi di layar.

---

### UC-21: Kelola & Suspend Pengguna
* **ID & Nama**: UC-21 Kelola & Suspend Pengguna
* **Aktor Utama**: Platform (Platform Owner)
* **Aktor Pendukung / Sistem Eksternal**: Supabase Database, Firebase FCM Service
* **Deskripsi**: Use case ini digunakan oleh pengelola platform untuk memantau pengguna terdaftar serta melakukan tindakan moderasi berupa pembekuan akun (suspend) bagi yang melanggar aturan.
* **Kondisi Awal (Preconditions)**: Pengguna login dengan peran `platform`.
* **Kondisi Akhir (Postconditions)**: Status akun pengguna diubah menjadi suspend (`is_suspended=true`), sesi token masuk dibatalkan, dan audit log tercatat.
* **Alur Utama (Basic Flow)**:
  1. Platform Owner membuka menu "Kelola Pengguna" di Platform Dashboard.
  2. Sistem mengambil data seluruh pengguna dari tabel `users` diurutkan berdasarkan tanggal daftar terbaru.
  3. Platform Owner mencari target pengguna menggunakan kolom pencarian (Username/Email) atau menggunakan filter peran.
  4. Platform Owner mengklik profil salah satu pengguna untuk melihat detail riwayat pelanggaran dan scrim yang diikuti.
  5. Platform Owner menekan tombol "Suspend Akun".
  6. Sistem meminta penginputan alasan pelanggaran penangguhan.
  7. Platform Owner memasukkan alasan, lalu menekan konfirmasi.
  8. Sistem melakukan UPDATE status pengguna menjadi `is_suspended = true` dan menyimpan alasan di kolom `suspension_reason`.
  9. Sistem menyimpan riwayat aksi ke tabel `audit_logs` dengan tipe aksi `suspend`.
  10. Sistem secara paksa membatalkan status JWT auth aktif milik pengguna bersangkutan di backend dan mengirim notifikasi FCM penangguhan.
  11. Pengguna target otomatis keluar dari aplikasi saat berinteraksi.
* **Alur Alternatif & Eksepsi (Alternative & Exception Flows)**:
  - **Alt-1: Mengaktifkan Kembali Akun (Unsuspend)**
    - Pada langkah 5, jika akun yang dipilih berstatus tersuspensi, tombol berubah menjadi "Unsuspend".
    - Platform Owner menekan tombol "Unsuspend".
    - Sistem melakukan UPDATE data pengguna menjadi `is_suspended = false` dan mengosongkan `suspension_reason`.
    - Sistem menyimpan record ke tabel `audit_logs` dengan tipe aksi `unsuspend`.
    - Firebase FCM mengirim push notifikasi "Akun Anda telah diaktifkan kembali" ke perangkat pengguna.

---

### UC-22: Approve/Reject Premium Request
* **ID & Nama**: UC-22 Approve/Reject Premium Request
* **Aktor Utama**: Platform (Platform Owner)
* **Aktor Pendukung / Sistem Eksternal**: Supabase Database, Firebase FCM Service
* **Deskripsi**: Use case ini digunakan oleh pengelola platform untuk meninjau pengajuan akun premium dari admin yang pembayarannya telah berhasil diselesaikan via Midtrans, kemudian mengaktifkan hak akses premium tersebut.
* **Kondisi Awal (Preconditions)**: Admin telah membayar paket premium (status `premium_requests = paid`).
* **Kondisi Akhir (Postconditions)**: Status request diperbarui, kolom `is_premium` admin disetel true, dan notifikasi push FCM dikirimkan.
* **Alur Utama (Basic Flow)**:
  1. Platform Owner membuka menu "Daftar Request Premium" di Platform Dashboard.
  2. Sistem menyajikan daftar antrean pengajuan premium yang berstatus `paid`.
  3. Platform Owner memilih salah satu pengajuan untuk melihat data admin dan nominal transfer.
  4. Platform Owner memverifikasi status pembayaran di dashboard eksternal Midtrans.
  5. Platform Owner menyetujui pengajuan dengan menekan tombol "Approve / Setujui".
  6. Sistem memperbarui status `premium_requests` menjadi `approved` beserta data waktu persetujuan.
  7. Sistem memperbarui data tabel `admin_profiles` target dengan mengubah status `is_premium = true` dan masa kadaluarsa premium diatur selama 30 hari ke depan (`premium_expired_at = now() + 30 days`).
  8. Sistem menyimpan transaksi pemasukan langganan baru ke tabel `transactions`.
  9. Sistem mencatat baris aksi ke tabel `audit_logs`.
  10. Firebase FCM mengirim push notifikasi "Selamat! Akun Premium Anda Telah Aktif" ke perangkat admin.
  11. Sistem memperbarui data antrean di layar.
* **Alur Alternatif & Eksepsi (Alternative & Exception Flows)**:
  - **Alt-1: Menolak Pengajuan (Reject)**
    - Pada langkah 5, jika terdeteksi fraud atau masalah data, Platform Owner memilih tombol "Reject / Tolak".
    - Sistem menampilkan input box alasan penolakan.
    - Platform Owner mengisi alasan dan menekan kirim.
    - Sistem mengubah status pengajuan menjadi `rejected` dan mencatat alasan penolakan.
    - Sistem menyimpan baris log ke `audit_logs` dan mengirim push notifikasi penolakan via FCM ke admin target.

---
*(Akhir Dokumen Spesifikasi Use Case BooyahHub)*
