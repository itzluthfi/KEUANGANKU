<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Danaku App - Atur Keuangan Praktis dengan AI</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Outfit', sans-serif;
        }
        body {
            background: linear-gradient(135deg, #FFF0F5 0%, #FFE4E1 100%);
            min-height: 100vh;
            color: #333;
            overflow-x: hidden;
        }
        header {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .logo {
            font-size: 24px;
            font-weight: 800;
            color: #FF528F;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .logo i {
            font-size: 28px;
        }
        .btn-portal {
            background: rgba(255, 255, 255, 0.7);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 82, 143, 0.2);
            padding: 10px 20px;
            border-radius: 30px;
            color: #FF528F;
            text-decoration: none;
            font-weight: 600;
            font-size: 14px;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.05);
        }
        .btn-portal:hover {
            background: #FF528F;
            color: white;
            transform: translateY(-2px);
        }
        .hero {
            max-width: 1200px;
            margin: 40px auto;
            padding: 20px;
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            min-height: 70vh;
        }
        .hero-text {
            flex: 1;
            min-width: 320px;
            padding-right: 40px;
        }
        .hero-text h1 {
            font-size: 48px;
            font-weight: 800;
            line-height: 1.2;
            margin-bottom: 20px;
            background: linear-gradient(45deg, #FF528F, #FF7A9F);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .hero-text p {
            font-size: 16px;
            color: #666;
            line-height: 1.6;
            margin-bottom: 30px;
        }
        .hero-img {
            flex: 1;
            min-width: 320px;
            display: flex;
            justify-content: center;
            align-items: center;
            position: relative;
        }
        .piggy-mockup {
            background: white;
            padding: 30px;
            border-radius: 40px;
            box-shadow: 0 20px 40px rgba(255, 82, 143, 0.15);
            border: 1px solid rgba(255, 255, 255, 0.6);
            display: flex;
            flex-direction: column;
            align-items: center;
            max-width: 360px;
            animation: float 4s ease-in-out infinite;
        }
        @keyframes float {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-10px); }
        }
        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            max-width: 1200px;
            margin: 60px auto;
            padding: 20px;
        }
        .feature-card {
            background: rgba(255, 255, 255, 0.6);
            backdrop-filter: blur(10px);
            padding: 25px;
            border-radius: 24px;
            border: 1px solid rgba(255, 255, 255, 0.8);
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.02);
            transition: all 0.3s ease;
        }
        .feature-card:hover {
            transform: translateY(-5px);
            background: white;
            box-shadow: 0 15px 35px rgba(255, 82, 143, 0.1);
        }
        .feature-icon {
            width: 50px;
            height: 50px;
            background: #FFE4E1;
            border-radius: 15px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #FF528F;
            font-size: 22px;
            margin-bottom: 20px;
        }
        .feature-card h3 {
            font-size: 18px;
            font-weight: 600;
            margin-bottom: 10px;
            color: #333;
        }
        .feature-card p {
            font-size: 13px;
            color: #666;
            line-height: 1.5;
        }
    </style>
</head>
<body>
    <header>
        <div class="logo">
            <i class="fa-solid fa-piggy-bank"></i>
            <span>Danaku</span>
        </div>
        <a href="/login" class="btn-portal"><i class="fa-solid fa-user-shield"></i> Portal Admin</a>
    </header>

    <main>
        <div class="hero">
            <div class="hero-text">
                <h1>Atur Keuangan Praktis,<br>Cerdas dengan AI</h1>
                <p>Danaku adalah asisten pencatat keuangan pribadi pintar berbasis mobile yang dilengkapi dengan kecerdasan buatan (Speech-to-Text & Vision OCR). Catat pemasukan, pantau tagihan rutin, kelola batas anggaran bulanan, dan cadangkan data secara real-time ke Awan.</p>
                <div style="display: flex; gap: 15px;">
                    <a href="/login" class="btn-portal" style="background:#FF528F; color:white; padding: 12px 28px;">Masuk Panel Admin</a>
                </div>
            </div>
            <div class="hero-img">
                <div class="piggy-mockup">
                    <img src="https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?q=80&w=400&auto=format&fit=crop" alt="Piggy Bank" style="width:120px; height:120px; border-radius:50%; object-fit:cover; margin-bottom:15px; border:3px solid #FFF0F5;">
                    <h3 style="color:#FF528F; font-size: 18px; font-weight:800;">Danaku App</h3>
                    <p style="font-size:11px; color:#999; text-align:center; margin-top:5px;">Sistem Asisten Pengatur Keuangan Premium Terintegrasi AI</p>
                </div>
            </div>
        </div>

        <div class="features-grid">
            <div class="feature-card">
                <div class="feature-icon"><i class="fa-solid fa-microphone"></i></div>
                <h3>Speech-to-Text AI</h3>
                <p>Cukup ucapkan pengeluaran Anda (misal: "Makan siang 20 ribu"), dan asisten AI kami akan mengurainya menjadi transaksi terperinci secara otomatis.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon"><i class="fa-solid fa-receipt"></i></div>
                <h3>Vision OCR Struk</h3>
                <p>Ambil foto struk belanja Anda. AI akan memindai barang, tanggal, kategori, dan nominal pengeluaran secara akurat dalam beberapa detik saja.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon"><i class="fa-solid fa-cloud-arrow-up"></i></div>
                <h3>Pencadangan Otomatis</h3>
                <p>Data tersimpan aman secara lokal di SQLite dan otomatis tersinkronisasi di server awan Laravel secara senyap ketika HP Anda online.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon"><i class="fa-solid fa-lock"></i></div>
                <h3>Kunci PIN Keamanan</h3>
                <p>Melindungi data finansial sensitif Anda dari akses yang tidak diinginkan dengan sistem kunci PIN 4-digit premium saat startup.</p>
            </div>
        </div>
    </main>
</body>
</html>
