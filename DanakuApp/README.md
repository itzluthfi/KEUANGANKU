# DanakuApp

DanakuApp adalah aplikasi pencatat keuangan lintas platform (*cross-platform*) modern yang dirancang untuk berjalan secara mulus di **Android (Smartphone & Tablet)** serta **Desktop (Windows)**. Aplikasi ini dibangun menggunakan *framework* Flutter dan dilengkapi dengan fitur manajemen dompet, analisis tren pengeluaran/pemasukan, dan antarmuka (*UI/UX*) yang responsif.

## Prasyarat (*Prerequisites*)

Sebelum mulai menjalankan aplikasi, pastikan Anda telah menginstal dan mengonfigurasi perangkat lunak berikut:
1. **Flutter SDK**: [Instalasi Flutter](https://docs.flutter.dev/get-started/install) (versi stabil terbaru direkomendasikan).
2. **Dart SDK**: Sudah sepaket saat Anda menginstal Flutter.
3. **IDE (Code Editor)**: Android Studio atau Visual Studio Code yang dilengkapi dengan ekstensi Flutter & Dart.
4. **Android Toolchain**: Diperlukan untuk *build* ke perangkat Android (diinstal melalui Android Studio).
5. **Windows Desktop Development**: Diperlukan untuk *build* ke Windows (Visual Studio 2022 dengan *workload* "Desktop development with C++").

Jalankan perintah ini di terminal untuk mengecek apakah *environment* Anda sudah siap:
```bash
flutter doctor
```
Pastikan tidak ada isu (*cross* merah) di bagian Android toolchain maupun Visual Studio untuk Windows.

---

## Cara Menjalankan Aplikasi (*Technical Guide*)

Sebelum melakukan *build* ke platform mana pun, buka terminal di *root directory* proyek (`DanakuApp`) dan jalankan perintah berikut untuk mengunduh seluruh dependensi aplikasi:

```bash
flutter pub get
```

### 1. Menjalankan di Android (Smartphone)
Untuk menjalankan aplikasi di emulator Android atau *smartphone* fisik:

1. Pastikan emulator Android Anda sudah dihidupkan, ATAU *smartphone* Android Anda sudah dicolokkan ke komputer (dengan mode **USB Debugging / Developer Options** aktif).
2. Anda bisa mengecek perangkat apa saja yang terbaca oleh sistem dengan perintah:
   ```bash
   flutter devices
   ```
3. Jalankan aplikasi (jika hanya ada 1 perangkat yang terdeteksi, Flutter akan otomatis memilihnya):
   ```bash
   flutter run
   ```
   *(Opsional)* Jika ada banyak perangkat, spesifikasikan ID perangkat:
   ```bash
   flutter run -d <device_id>
   ```

### 2. Menjalankan di Android (Tablet)
Kode dasar (*codebase*) yang digunakan untuk Android *Smartphone* dan *Tablet* adalah **100% sama**. DanakuApp sudah mengimplementasikan `LayoutBuilder` dan `MediaQuery` sehingga tampilannya otomatis beradaptasi (responsif) ketika dijalankan di layar besar.

1. Buka AVD Manager di Android Studio, klik "Create Virtual Device", lalu pilih *hardware* berjenis **Tablet** (contoh: Pixel Tablet, Pixel C, atau Nexus 9).
2. Jalankan emulator Tablet tersebut.
3. Eksekusi perintah yang sama di terminal:
   ```bash
   flutter run
   ```

### 3. Menjalankan di Desktop (Windows)
Aplikasi ini sudah dioptimalkan untuk berjalan di Desktop dengan ukuran *window* yang dinamis (bisa di-*resize* lebar/sempit).

1. Aktifkan *support* untuk Windows (biasanya sudah aktif *default* di versi Flutter baru):
   ```bash
   flutter config --enable-windows-desktop
   ```
2. Jalankan proyek sebagai aplikasi Windows lokal:
   ```bash
   flutter run -d windows
   ```
3. *(Opsional)* Jika Anda ingin menghasilkan *file executable* (`.exe`) murni tanpa *debug mode* untuk di-deploy:
   ```bash
   flutter build windows
   ```
   Hasil *build* aplikasi (.exe) nantinya akan tersimpan di dalam struktur *folder*:
   `build\windows\x64\runner\Release\`

---

## Fitur Utama Aplikasi
- **Dashboard Responsif**: Mode kalender untuk memantau hari apa saja yang memiliki pengeluaran atau pemasukan.
- **Multi-Buku Catatan**: Pisahkan catatan keuangan sesuai kebutuhan (misal: "Keuangan Pribadi" dan "Keuangan Bisnis") secara rapi.
- **Manajemen Aset (Dompet)**: Pencatatan saldo dinamis untuk Dompet, Rekening Bank, maupun E-Wallet yang saling tersinkronisasi dengan histori transaksi.
- **Report & Analisis Cerdas**: Pantau persentase alokasi pengeluaran melalui *Donut Chart*, serta deteksi otomatis apakah Anda mengalami Surplus (menabung) atau Defisit di bulan ini lewat *Trend Graph*.
