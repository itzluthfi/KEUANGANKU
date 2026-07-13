<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kebijakan Privasi - Danaku App</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Outfit', sans-serif;
        }
        body {
            background-color: #09090B;
            background-image: 
                radial-gradient(at 0% 0%, rgba(255, 82, 143, 0.08) 0, transparent 50%), 
                radial-gradient(at 100% 100%, rgba(255, 82, 143, 0.05) 0, transparent 50%);
            color: #F4F4F5;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            line-height: 1.6;
        }
        .container {
            max-width: 800px;
            width: 100%;
            margin: 0 auto;
            padding: 40px 20px;
            flex: 1;
        }
        header {
            text-align: center;
            margin-bottom: 40px;
        }
        .logo {
            font-size: 28px;
            font-weight: 800;
            color: #FFF;
            display: inline-flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 15px;
        }
        .logo i {
            color: #FF528F;
            filter: drop-shadow(0 0 8px rgba(255, 82, 143, 0.5));
        }
        h1 {
            font-size: 32px;
            font-weight: 800;
            margin-bottom: 10px;
            color: #FFF;
        }
        .last-update {
            color: #A1A1AA;
            font-size: 14px;
        }
        .content-card {
            background: rgba(255, 255, 255, 0.02);
            backdrop-filter: blur(12px);
            border: 1px solid rgba(255, 255, 255, 0.05);
            padding: 30px;
            border-radius: 24px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            margin-bottom: 30px;
        }
        h2 {
            font-size: 20px;
            font-weight: 700;
            color: #FF528F;
            margin-top: 25px;
            margin-bottom: 12px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        h2:first-of-type {
            margin-top: 0;
        }
        p {
            color: #D4D4D8;
            font-size: 15px;
            margin-bottom: 15px;
            text-align: justify;
        }
        ul {
            margin-left: 20px;
            margin-bottom: 15px;
            color: #D4D4D8;
            font-size: 15px;
        }
        li {
            margin-bottom: 8px;
        }
        .footer-text {
            text-align: center;
            color: #71717A;
            font-size: 13px;
            margin-top: 40px;
        }
        .btn-back {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.1);
            color: #FFF;
            padding: 10px 20px;
            border-radius: 12px;
            text-decoration: none;
            font-size: 14px;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.2s ease;
            margin-bottom: 20px;
        }
        .btn-back:hover {
            background: rgba(255, 82, 143, 0.1);
            border-color: rgba(255, 82, 143, 0.3);
            color: #FF528F;
        }
    </style>
</head>
<body>
    <div class="container">
        <a href="/" class="btn-back"><i class="fa-solid fa-arrow-left"></i> Kembali ke Beranda</a>
        
        <header>
            <div class="logo">
                <i class="fa-solid fa-piggy-bank"></i>
                <span>Danaku</span>
            </div>
            <h1>Kebijakan Privasi</h1>
            <div class="last-update">Terakhir diperbarui: 13 Juli 2026</div>
        </header>

        <div class="content-card">
            <h2><i class="fa-solid fa-shield-halved"></i> 1. Ikhtisar & Penyimpanan Data Lokal</h2>
            <p>Danaku berkomitmen penuh untuk melindungi privasi data keuangan Anda. Secara default, seluruh data transaksi, dompet, kategori anggaran, target tabungan, dan riwayat obrolan AI Anda disimpan secara eksklusif di dalam memori penyimpanan internal perangkat telepon Anda menggunakan database terenkripsi SQLite lokal.</p>
            <p>Kami tidak memiliki akses langsung untuk membaca, melihat, atau memanipulasi data transaksi harian Anda yang disimpan secara lokal tersebut.</p>

            <h2><i class="fa-solid fa-cloud-arrow-up"></i> 2. Layanan Pencadangan Awan (Cloud Backup)</h2>
            <p>Danaku menyediakan modul pencadangan awan opsional ("Backup Awan") untuk membantu Anda mengamankan data jika perangkat Anda hilang atau rusak. Jika Anda memutuskan untuk mendaftarkan akun di server awan kami:</p>
            <ul>
                <li>Kami mengumpulkan alamat email dan password terenkripsi Anda untuk keperluan otentikasi akun.</li>
                <li>Data transaksi lokal, dompet, dan kategori diunggah melalui protokol HTTPS yang aman dan disimpan di server terenkripsi kami.</li>
                <li>Kami tidak menggunakan data cadangan Anda untuk tujuan periklanan atau membagikannya kepada pihak ketiga mana pun. Data ini murni hanya digunakan untuk fungsi pemulihan data (Restore) Anda.</li>
            </ul>

            <h2><i class="fa-solid fa-robot"></i> 3. Pemrosesan Data Cerdas AI</h2>
            <p>Danaku menggunakan teknologi kecerdasan buatan untuk fitur pencatatan suara (Speech-to-Text) dan pemindaian struk (Vision OCR):</p>
            <ul>
                <li><strong>Catatan Suara</strong>: Rekaman suara/teks transkrip Anda dikirimkan ke model kecerdasan buatan kami hanya untuk mengurai nominal, deskripsi, dan kategori transaksi secara real-time.</li>
                <li><strong>Scan Struk Belanja</strong>: Foto struk belanja yang Anda unggah dikirimkan secara aman ke API pendeteksi teks OCR kami untuk diekstraksi menjadi baris item transaksi belanja.</li>
                <li>Data transaksi hasil ekstraksi ini tidak disimpan secara permanen di log pemrosesan AI kami dan segera dihapus setelah proses ekstraksi data selesai dikembalikan ke aplikasi Anda.</li>
            </ul>

            <h2><i class="fa-solid fa-trash-can"></i> 4. Penghapusan Akun dan Data (Data Deletion)</h2>
            <p>Sesuai dengan ketentuan Google Play Store, Anda memiliki hak penuh untuk menghapus seluruh data Anda kapan saja. Anda dapat mengajukan penghapusan akun secara permanen secara langsung dari menu pengaturan di dalam aplikasi Danaku ("Hapus Akun Awan").</p>
            <p>Ketika Anda menghapus akun awan Anda:</p>
            <ul>
                <li>Seluruh data profil akun Anda akan dihapus secara permanen dari server database kami.</li>
                <li>Seluruh file cadangan (backups) yang pernah Anda unggah akan dihapus seketika dan tidak dapat dipulihkan kembali.</li>
                <li>Seluruh catatan riwayat log transaksi di server kami yang terkait dengan akun Anda akan dibersihkan tanpa sisa.</li>
            </ul>

            <h2><i class="fa-solid fa-circle-info"></i> 5. Hubungi Kami</h2>
            <p>Jika Anda memiliki pertanyaan tentang Kebijakan Privasi ini atau ingin menyampaikan keluhan mengenai pengelolaan data finansial Anda, silakan hubungi tim pengembang Danaku melalui email di <strong>support@danaku.dev</strong>.</p>
        </div>

        <div class="footer-text">
            © 2026 Danaku Developer Team. Hak Cipta Dilindungi Undang-Undang.
        </div>
    </div>
</body>
</html>
