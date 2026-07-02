# Danaku API - Panduan Sinkronisasi & Cadangan Database Supabase

Repository ini adalah backend API berbasis Laravel untuk aplikasi pencatatan keuangan **DanakuApp** (Flutter). Sistem ini menggunakan arsitektur *offline-first* di mana data disimpan secara lokal pada SQLite HP, dan backend ini digunakan sebagai server cadangan (*cloud backup & restore*) yang terhubung ke cloud database **Supabase**.

---

## 🛠️ Prasyarat (Prerequisites)

Sebelum menjalankan aplikasi, pastikan komputer Anda telah memenuhi persyaratan berikut:
1. **PHP >= 8.2** dengan ekstensi berikut yang sudah diaktifkan di `php.ini`:
   * `pdo_pgsql` & `pgsql` (untuk koneksi PostgreSQL Supabase)
   * `mbstring` (untuk kebutuhan manipulasi string Laravel)
2. **Composer** terinstal.
3. Akun **Supabase** (database cloud gratis).
4. **Ngrok** terinstal (untuk menghubungkan HP fisik Anda ke server lokal komputer Anda).

---

## ⚙️ 1. Konfigurasi Database Supabase

1. Buka dashboard proyek Supabase Anda.
2. Dapatkan detail **Connection Pooler** melalui menu **Settings** -> **Database** -> **Connection Pooler** (salin Host dan Port).
3. Buka file `.env` di proyek Laravel ini, lalu sesuaikan bagian konfigurasinya:

```env
DB_CONNECTION=pgsql
DB_HOST=aws-1-ap-southeast-1.pooler.supabase.com  # <--- Ganti dengan Host Pooler Anda
DB_PORT=5432                                      # <--- Port Pooler
DB_DATABASE=postgres
DB_USERNAME=postgres.crskhsyozfzypmpatxmv         # <--- Ganti dengan username pooler Anda
DB_PASSWORD="PasswordDatabaseSupabaseAnda"        # <--- Password database Supabase Anda
```

> ⚠️ **Catatan penting:** Pastikan tidak ada variabel `DB_URL` di dalam file `.env` Anda agar konfigurasi detail di atas tidak terabaikan.

---

## 🚀 2. Migrasi & Seeding Data Dummy (10.000 Transaksi)

Untuk menyiapkan database pertama kali dan mengisinya dengan 10.000 data dummy transaksi keuangan acak sejak Januari 2025:

1. Bersihkan tabel lama dan jalankan migrasi database di Supabase:
   ```bash
   php artisan migrate:fresh
   ```
2. Jalankan seeder untuk membuat akun uji coba beserta data transaksinya:
   ```bash
   php artisan db:seed
   ```
   *Seeder ini akan membuat:*
   * **Akun Login:** Email `mada@email.com` dan password `mada123`.
   * **Data Dummy:** 10.000 data transaksi acak (pemasukan & pengeluaran), 5 e-wallet (GoPay, OVO, Dana, dll.), dan 12 kategori keuangan yang tersebar sejak Januari 2025.

---

## 📱 3. Menghubungkan Laptop ke HP (Development Testing)

Karena server Laravel berjalan di komputer lokal Anda, gunakan **Ngrok** agar HP fisik Anda dapat mengakses API tersebut melalui internet:

1. **Jalankan Server Laravel** di port `8001`:
   ```bash
   php artisan serve --port=8001
   ```
2. **Jalankan Tunneling Ngrok** di terminal terpisah untuk mengarah ke port tersebut:
   ```bash
   ngrok http 127.0.0.1:8001
   ```
3. Salin URL publik aman yang dihasilkan oleh Ngrok, contohnya:
   `https://ditzy-common-small.ngrok-free.dev`

---

## 💻 4. Konfigurasi di Aplikasi Flutter (DanakuApp)

1. Buka file **`lib/services/sync_service.dart`** di proyek Flutter Anda.
2. Pastikan variabel **`useRealServer`** diset ke `true`:
   ```dart
   final bool useRealServer = true;
   ```
3. Ganti nilai **`laravelBaseUrl`** dengan alamat Ngrok Anda:
   ```dart
   final String laravelBaseUrl = "https://ditzy-common-small.ngrok-free.dev/api";
   ```
4. Simpan file (`Ctrl + S`) dan jalankan aplikasi Flutter Anda di HP.

---

## 🧪 5. Cara Pengujian Fitur di Aplikasi HP

1. **Login Akun:**
   Masuk ke menu akun di aplikasi HP Anda, lalu login menggunakan:
   * **Email:** `mada@email.com`
   * **Password:** `mada123`
2. **Pulihkan Data (Restore):**
   Masuk ke tab sinkronisasi/pengaturan, lalu klik tombol **Restore (Pulihkan Data)**. Aplikasi akan mengunduh dan menyinkronkan 10.000 transaksi dummy sejak Januari 2025 tersebut langsung ke HP Anda.
3. **Pencadangan Otomatis (Auto-Backup):**
   Setiap kali Anda menambah, mengedit, atau menghapus transaksi di HP, aplikasi akan otomatis mengirimkan cadangan data terbaru ke Supabase di background secara senyap (*auto-backup*).
