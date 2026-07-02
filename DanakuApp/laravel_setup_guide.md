# 🚀 Panduan Lengkap: Pembuatan & Deploy Laravel Backend (API Awan DanakuApp)

Panduan ini akan membimbing Anda langkah demi langkah untuk membuat proyek backend **Laravel 11** baru dari nol di folder lain di komputer Anda, mengonfigurasi API pencadangan awan, menguploadnya ke GitHub, hingga men-deploy-nya secara gratis ke **Railway** atau **Render**.

---

## 🛠️ Langkah 1: Persiapan & Inisialisasi Proyek Baru

Buka terminal baru di komputer Anda (jangan di dalam folder Flutter DanakuApp, melainkan di folder kuliah/project Anda yang lain), lalu ikuti perintah berikut:

1. **Buat Proyek Laravel Baru:**
   ```bash
   composer create-project laravel/laravel DanakuBackend
   ```
2. **Masuk ke Folder Proyek Baru Anda:**
   ```bash
   cd DanakuBackend
   ```
3. **Instalasi API Laravel 11 (SANGAT PENTING):**
   Laravel 11 secara default tidak memiliki folder `routes/api.php`. Jalankan perintah ini untuk mengaktifkan modul API dan menginstal **Laravel Sanctum** secara otomatis:
   ```bash
   php artisan install:api
   ```

---

## 🗄️ Langkah 2: Membuat Database Migration untuk Backup

Data cadangan dari Flutter dikirim dalam bentuk payload JSON terkompresi. Kita akan membuat tabel database di Laravel untuk menyimpan payload ini terikat dengan akun pengguna.

1. **Buat Berkas Migration:**
   ```bash
   php artisan make:migration create_backups_table
   ```
2. Buka berkas migration yang baru dibuat di folder `database/migrations/xxxx_create_backups_table.php`, lalu sesuaikan metodenya menjadi:
   ```php
   public function up(): void {
       Schema::create('backups', function (Blueprint $table) {
           $table->id();
           $table->foreignId('user_id')->constrained()->onDelete('cascade');
           $table->longText('data'); // Menyimpan Payload JSON transaksi, dompet, & kategori
           $table->timestamps();
       });
   }

   public function down(): void {
       Schema::dropIfExists('backups');
   }
   ```

---

## 🧬 Langkah 3: Membuat Model & Controller

### 1. Model `Backup`
Buat berkas model baru di `app/Models/Backup.php`:
```bash
php artisan make:model Backup
```
Buka file `app/Models/Backup.php`, dan ubah kodenya menjadi:
```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Backup extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'data',
    ];

    // Relasi balik ke User
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
```

---

### 2. Controller `AuthController` (Otentikasi Akun)
Buat berkas controller baru untuk pendaftaran dan login pengguna:
```bash
php artisan make:controller API/AuthController
```
Buka file `app/Http/Controllers/API/AuthController.php`, lalu salin kode berikut:
```php
<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'email' => 'required|email|unique:users',
            'password' => 'required|min:6',
        ]);

        $user = User::create([
            'name' => explode('@', $request->email)[0],
            'email' => $request->email,
            'password' => Hash::make($request->password),
        ]);

        return response()->json([
            'message' => 'Pendaftaran sukses!',
            'user' => $user
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Kredensial salah!'], 401);
        }

        // Token ini akan disimpan di SQLite HP Anda untuk hak akses selanjutnya
        $token = $user->createToken('DanakuAppToken')->plainTextToken;

        return response()->json([
            'message' => 'Login Berhasil!',
            'token' => $token,
            'email' => $user->email
        ], 200);
    }
}
```

---

### 3. Controller `BackupController` (Pencadangan & Pemulihan)
Buat berkas controller baru untuk menyimpan dan memulihkan data:
```bash
php artisan make:controller API/BackupController
```
Buka file `app/Http/Controllers/API/BackupController.php`, lalu salin kode berikut:
```php
<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Backup;
use Illuminate\Http\Request;

class BackupController extends Controller
{
    public function backup(Request $request)
    {
        $user = $request->user();

        // Menyimpan baru atau menimpa cadangan lama milik user ini
        $backup = Backup::updateOrCreate(
            ['user_id' => $user->id],
            ['data' => json_encode($request->all())]
        );

        return response()->json([
            'message' => 'Data berhasil dicadangkan ke server!',
            'backup_date' => now()->toIso8601String()
        ], 200);
    }

    public function restore(Request $request)
    {
        $user = $request->user();
        $backup = Backup::where('user_id', $user->id)->first();

        if (!$backup) {
            return response()->json(['message' => 'Tidak ditemukan data cadangan untuk akun ini!'], 404);
        }

        return response()->json([
            'message' => 'Data cadangan ditemukan!',
            'data' => json_decode($backup->data)
        ], 200);
    }
}
```

---

## 🌐 Langkah 4: Mendaftarkan Rute Rute API

Buka file rute API Anda di `routes/api.php`, lalu ganti seluruh isinya dengan kode berikut:
```php
<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\BackupController;

// Rute Publik (Bisa diakses tanpa login)
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Rute Privat (Wajib menyertakan Bearer Token Sanctum di Header HTTP)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/backup', [BackupController::class, 'backup']);
    Route::get('/restore', [BackupController::class, 'restore']);
});
```

---

## 📶 Langkah 5: Pengujian Lokal dengan Emulator Android

Jika Anda menjalankan server di laptop secara lokal menggunakan:
```bash
php artisan serve
```
Dan Anda mengujinya menggunakan **Android Emulator**, pastikan base URL di Flutter `sync_service.dart` adalah:
`http://10.0.2.2:8000/api`.

Jika menggunakan **HP Fisik**, pastikan satu Wi-Fi, jalankan server dengan:
`php artisan serve --host 0.0.0.0 --port 8000`, lalu arahkan URL ke IP Laptop Anda (misal: `http://192.168.1.15:8000/api`).

---

## 🚀 Langkah 6: Upload ke GitHub & Deploy ke Railway

Setelah tes lokal berjalan lancar, saatnya men-deploy secara gratis agar bisa diakses lewat internet sungguhan!

### A. Upload Proyek Laravel ke GitHub
1. Buat repositori baru di GitHub dengan nama `danaku-backend` (Private/Public).
2. Di dalam folder proyek Laravel Anda (`DanakuBackend`), jalankan perintah git berikut:
   ```bash
   git init
   git add .
   git commit -m "first commit"
   git branch -M main
   git remote add origin https://github.com/USERNAME-ANDA/danaku-backend.git
   git push -u origin main
   ```

### B. Hubungkan ke Railway
1. Buka [Railway.app](https://railway.app) dan login dengan akun GitHub Anda.
2. Klik **New Project** $\rightarrow$ **Deploy from GitHub repo** $\rightarrow$ Pilih `danaku-backend`.
3. Tambahkan database MySQL di Railway: Klik **New** $\rightarrow$ **Database** $\rightarrow$ **MySQL**. Railway akan membuatkan database instan.
4. Hubungkan Laravel ke Database MySQL di Railway:
   * Klik layanan `danaku-backend` di Railway, masuk ke tab **Variables**.
   * Tambahkan variabel environment berikut (Railway akan otomatis mendeteksi variabel MySQL):
     * `DB_CONNECTION` = `mysql`
     * `DB_HOST` = `${{MySQL.MYSQL_RAW_URL}}` (Atau klik referensi dari database MySQL Anda)
     * `APP_KEY` = *Salin APP_KEY dari file .env lokal laptop Anda*
5. Klik **Deploy**. Setelah berhasil, masuk ke tab **Settings** pada layanan Laravel Anda di Railway, lalu klik **Generate Domain** untuk mendapatkan URL HTTPS gratis (misal: `https://danaku-backend.up.railway.app`).

### C. Hubungkan Aplikasi Flutter ke Domain Railway
Buka berkas `lib/services/sync_service.dart` di Flutter Anda, lalu ganti baris ke-15 menjadi domain HTTPS Anda:
```dart
final String laravelBaseUrl = "https://danaku-backend.up.railway.app/api";
```

**Selesai!** Proyek backend Laravel Anda sekarang telah aktif, aman, online 24 jam, dan siap melayani pencadangan awan asli DanakuApp!
