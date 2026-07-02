<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Backup;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon;

class BackupSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Buat atau update user Mada
        $user = User::updateOrCreate(
            ['email' => 'mada@email.com'],
            [
                'name' => 'Mada',
                'password' => Hash::make('mada123'),
            ]
        );

        // 2. Definisikan wallets sesuai schema SQLite di Flutter (nama, saldo, jenis, icon_code)
        $wallets = [
            ['id' => 1, 'book_id' => 1, 'nama' => 'GoPay', 'saldo' => 1500000, 'jenis' => 'Akun Virtual', 'icon_code' => 57409],
            ['id' => 2, 'book_id' => 1, 'nama' => 'OVO', 'saldo' => 500000, 'jenis' => 'Akun Virtual', 'icon_code' => 57409],
            ['id' => 3, 'book_id' => 1, 'nama' => 'Dana', 'saldo' => 750000, 'jenis' => 'Akun Virtual', 'icon_code' => 57409],
            ['id' => 4, 'book_id' => 1, 'nama' => 'ShopeePay', 'saldo' => 300000, 'jenis' => 'Akun Virtual', 'icon_code' => 57409],
            ['id' => 5, 'book_id' => 1, 'nama' => 'Dompet Tunai', 'saldo' => 1200000, 'jenis' => 'Dompet Fisik', 'icon_code' => 57409],
        ];

        // 3. Definisikan categories sesuai schema SQLite di Flutter (nama, jenis: 'keluar' / 'masuk', icon_code)
        $categories = [
            ['id' => 1, 'nama' => 'Makanan & Minuman', 'jenis' => 'keluar', 'icon_code' => 57954],
            ['id' => 2, 'nama' => 'Transportasi', 'jenis' => 'keluar', 'icon_code' => 58674],
            ['id' => 3, 'nama' => 'Belanja', 'jenis' => 'keluar', 'icon_code' => 57900],
            ['id' => 4, 'nama' => 'Hiburan', 'jenis' => 'keluar', 'icon_code' => 58162],
            ['id' => 5, 'nama' => 'Kesehatan', 'jenis' => 'keluar', 'icon_code' => 58291],
            ['id' => 6, 'nama' => 'Pendidikan', 'jenis' => 'keluar', 'icon_code' => 57939],
            ['id' => 7, 'nama' => 'Tagihan & Listrik', 'jenis' => 'keluar', 'icon_code' => 58266],
            ['id' => 8, 'nama' => 'Gaji', 'jenis' => 'masuk', 'icon_code' => 57895],
            ['id' => 9, 'nama' => 'Uang Saku', 'jenis' => 'masuk', 'icon_code' => 57895],
            ['id' => 10, 'nama' => 'Transfer Masuk', 'jenis' => 'masuk', 'icon_code' => 57895],
            ['id' => 11, 'nama' => 'Lain-lain (Masuk)', 'jenis' => 'masuk', 'icon_code' => 57895],
            ['id' => 12, 'nama' => 'Lain-lain (Keluar)', 'jenis' => 'keluar', 'icon_code' => 57895],
        ];

        // List catatan per kategori untuk variasi data
        $notesList = [
            1 => ['Beli nasi goreng', 'Makan siang bakso', 'Kopi Starbucks', 'Gofood martabak', 'Beli cemilan', 'Makan malam penyetan', 'Beli air mineral', 'Makan siang warteg', 'Beli roti bakar'],
            2 => ['Bensin motor', 'Grab/Gojek ride', 'Tiket kereta KRL', 'E-toll', 'Servis motor bulanan', 'Biaya parkir', 'Gocar ke mal'],
            3 => ['Beli baju kaos', 'Belanja bulanan Alfamart', 'Beli sepatu baru', 'Belanja Indomaret', 'Beli sabun & shampoo', 'Belanja online Tokopedia', 'Beli aksesoris'],
            4 => ['Tiket bioskop XXI', 'Netflix bulanan', 'Spotify premium', 'Beli game Steam', 'Nongkrong di kafe', 'Beli tiket konser', 'Main timezone'],
            5 => ['Beli obat apotek', 'Minyak kayu putih', 'Beli Vitamin C', 'Konsultasi dokter', 'Beli masker'],
            6 => ['Beli buku tulis', 'Beli novel', 'Biaya kursus online', 'Uang kuliah semester', 'Alat tulis kantor'],
            7 => ['Bayar token listrik', 'Tagihan internet WiFi', 'Pulsa HP bulanan', 'Beli paket data', 'Tagihan air PDAM'],
            8 => ['Gaji bulanan kantor', 'Bonus performa kerja', 'Fee project freelance'],
            9 => ['Uang saku bulanan', 'Jajan pemberian orang tua'],
            10 => ['Transfer dari teman', 'Pengembalian uang (Refund)', 'Patungan makan siang'],
            11 => ['Temukan uang di jalan', 'Jual barang bekas'],
            12 => ['Biaya admin bank', 'Sedekah masjid', 'Uang tip driver', 'Denda telat bayar']
        ];

        $transactions = [];
        $startDate = Carbon::create(2025, 1, 1);
        $endDate = Carbon::create(2026, 6, 20);
        $totalDays = $startDate->diffInDays($endDate);

        // 4. Generate 10000 data transaksi acak sesuai schema SQLite (id, book_id, keterangan, jumlah, jenis, tanggal, walletNama, kategori)
        for ($i = 1; $i <= 10000; $i++) {
            // Pilih kategori acak
            $category = $categories[array_rand($categories)];
            $categoryId = $category['id'];
            $categoryName = $category['nama'];
            $jenis = $category['jenis']; // 'keluar' / 'masuk'

            // Pilih dompet acak
            $wallet = $wallets[array_rand($wallets)];
            $walletName = $wallet['nama'];

            // Generate tanggal acak di rentang waktu
            $randomDays = rand(0, $totalDays);
            $date = (clone $startDate)->addDays($randomDays)->addHours(rand(8, 22))->addMinutes(rand(0, 59));

            // Tentukan nominal acak berdasarkan kategori
            $amount = 0;
            if ($jenis === 'masuk') {
                if ($categoryId === 8) { // Gaji
                    $amount = rand(40, 80) * 100000;
                } elseif ($categoryId === 9) { // Uang Saku
                    $amount = rand(10, 50) * 10000;
                } else { // Transfer / Lain-lain
                    $amount = rand(5, 100) * 5000;
                }
            } else { // Keluar
                if ($categoryId === 1) { // Makanan
                    $amount = rand(1, 15) * 10000;
                } elseif ($categoryId === 2) { // Transport
                    $amount = rand(1, 10) * 5000;
                } elseif ($categoryId === 3) { // Belanja
                    $amount = rand(5, 100) * 10000;
                } elseif ($categoryId === 4) { // Hiburan
                    $amount = rand(3, 30) * 10000;
                } elseif ($categoryId === 6) { // Pendidikan
                    $amount = rand(5, 50) * 20000;
                } elseif ($categoryId === 7) { // Tagihan
                    $amount = rand(5, 60) * 10000;
                } else {
                    $amount = rand(2, 40) * 5000;
                }
            }

            // Pilih catatan acak yang sesuai dengan kategori
            $notesOptions = $notesList[$categoryId];
            $notes = $notesOptions[array_rand($notesOptions)];

            $transactions[] = [
                'id' => $i,
                'book_id' => 1,
                'keterangan' => $notes,
                'jumlah' => $amount,
                'jenis' => $jenis, // 'keluar' atau 'masuk'
                'tanggal' => $date->toIso8601String(),
                'walletNama' => $walletName,
                'kategori' => $categoryName,
            ];
        }

        // Urutkan transaksi berdasarkan tanggal secara menaik (ascending)
        usort($transactions, function ($a, $b) {
            return strcmp($a['tanggal'], $b['tanggal']);
        });

        // 5. Simpan seluruh payload JSON ke tabel backups untuk user mada@email.com
        $payload = [
            'wallets' => $wallets,
            'categories' => $categories,
            'transaksi' => $transactions,
        ];

        Backup::updateOrCreate(
            ['user_id' => $user->id],
            ['data' => json_encode($payload)]
        );

        $this->command->info("Dummy User mada@email.com berhasil dibuat dengan password: mada123");
        $this->command->info("10,000 data dummy transaksi, kategori, & e-wallet berhasil disimpan sebagai cadangan.");
    }
}
