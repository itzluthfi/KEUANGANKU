<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Danaku App - Atur Keuangan Praktis dengan AI</title>
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
                radial-gradient(at 50% 0%, rgba(74, 144, 226, 0.08) 0, transparent 50%),
                radial-gradient(at 100% 100%, rgba(255, 82, 143, 0.05) 0, transparent 50%),
                linear-gradient(rgba(255, 255, 255, 0.007) 1px, transparent 1px),
                linear-gradient(90deg, rgba(255, 255, 255, 0.007) 1px, transparent 1px);
            background-size: 100% 100%, 100% 100%, 100% 100%, 40px 40px, 40px 40px;
            color: #F4F4F5;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            overflow-x: hidden;
        }
        header {
            max-width: 1200px;
            width: 100%;
            margin: 0 auto;
            padding: 24px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            z-index: 10;
        }
        .logo {
            font-size: 26px;
            font-weight: 800;
            color: #FFF;
            display: flex;
            align-items: center;
            gap: 12px;
            letter-spacing: -0.5px;
        }
        .logo i {
            color: #FF528F;
            filter: drop-shadow(0 0 8px rgba(255, 82, 143, 0.5));
            font-size: 28px;
        }
        .btn-portal {
            background: rgba(255, 255, 255, 0.03);
            backdrop-filter: blur(12px);
            border: 1px solid rgba(255, 255, 255, 0.08);
            padding: 10px 24px;
            border-radius: 30px;
            color: #FFF;
            text-decoration: none;
            font-weight: 600;
            font-size: 14px;
            transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
            display: inline-flex;
            align-items: center;
            gap: 8px;
            box-shadow: 0 4px 30px rgba(0, 0, 0, 0.2);
        }
        .btn-portal:hover {
            background: rgba(255, 82, 143, 0.1);
            border-color: rgba(255, 82, 143, 0.4);
            color: #FF528F;
            transform: translateY(-2px);
            box-shadow: 0 0 15px rgba(255, 82, 143, 0.2);
        }
        .btn-portal-primary {
            background: linear-gradient(135deg, #FF528F 0%, #FF7A9F 100%);
            border: none;
            box-shadow: 0 0 25px rgba(255, 82, 143, 0.3);
        }
        .btn-portal-primary:hover {
            background: linear-gradient(135deg, #FF7A9F 0%, #FF9EBA 100%);
            color: white;
            border-color: transparent;
            box-shadow: 0 0 35px rgba(255, 82, 143, 0.5);
        }
        .hero {
            max-width: 1200px;
            margin: 40px auto;
            padding: 20px;
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            flex: 1;
            z-index: 10;
        }
        .hero-text {
            flex: 1.2;
            min-width: 320px;
            padding-right: 60px;
        }
        .hero-text h1 {
            font-size: 56px;
            font-weight: 800;
            line-height: 1.15;
            margin-bottom: 24px;
            letter-spacing: -1.5px;
            color: #FFF;
        }
        .hero-text h1 span {
            background: linear-gradient(to right, #FF528F, #4A90E2);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            filter: drop-shadow(0 2px 10px rgba(255, 82, 143, 0.15));
        }
        .hero-text p {
            font-size: 16px;
            color: #A1A1AA;
            line-height: 1.7;
            margin-bottom: 36px;
            font-weight: 400;
        }
        .hero-img {
            flex: 0.8;
            min-width: 320px;
            display: flex;
            justify-content: center;
            align-items: center;
            position: relative;
        }
        .glow-bg {
            position: absolute;
            width: 350px;
            height: 350px;
            background: radial-gradient(circle, rgba(255, 82, 143, 0.2) 0%, rgba(74, 144, 226, 0.1) 60%, transparent 100%);
            filter: blur(50px);
            z-index: -1;
            animation: pulse 6s ease-in-out infinite alternate;
        }
        @keyframes pulse {
            0% { transform: scale(0.9) translate(0px, 0px); }
            100% { transform: scale(1.1) translate(10px, -10px); }
        }
        .phone-mockup {
            background: rgba(20, 20, 28, 0.6);
            backdrop-filter: blur(20px);
            padding: 24px;
            border-radius: 40px;
            box-shadow: 
                0 30px 60px rgba(0, 0, 0, 0.4), 
                inset 0 1px 0 rgba(255, 255, 255, 0.1);
            border: 1px solid rgba(255, 255, 255, 0.08);
            display: flex;
            flex-direction: column;
            align-items: center;
            max-width: 340px;
            width: 100%;
            animation: float 5s ease-in-out infinite;
        }
        @keyframes float {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-12px); }
        }
        .phone-mockup img {
            width: 100%;
            height: 200px;
            border-radius: 24px;
            object-fit: cover;
            margin-bottom: 20px;
            border: 1px solid rgba(255, 255, 255, 0.05);
            box-shadow: 0 10px 20px rgba(0,0,0,0.3);
        }
        .phone-mockup h3 {
            color: #FFF;
            font-size: 20px;
            font-weight: 700;
            letter-spacing: -0.3px;
        }
        .phone-mockup p {
            font-size: 12px;
            color: #71717A;
            text-align: center;
            margin-top: 6px;
            line-height: 1.4;
        }
        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
            gap: 24px;
            max-width: 1200px;
            width: 100%;
            margin: 60px auto;
            padding: 20px;
            z-index: 10;
        }
        .feature-card {
            background: rgba(255, 255, 255, 0.02);
            backdrop-filter: blur(16px);
            padding: 30px;
            border-radius: 28px;
            border: 1px solid rgba(255, 255, 255, 0.04);
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
            transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
        }
        .feature-card:hover {
            transform: translateY(-8px);
            background: rgba(255, 255, 255, 0.04);
            border-color: rgba(255, 82, 143, 0.2);
            box-shadow: 
                0 20px 40px rgba(0, 0, 0, 0.2), 
                0 0 25px rgba(255, 82, 143, 0.05);
        }
        .feature-icon {
            width: 52px;
            height: 52px;
            background: rgba(255, 82, 143, 0.1);
            border-radius: 16px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #FF528F;
            font-size: 24px;
            margin-bottom: 24px;
            border: 1px solid rgba(255, 82, 143, 0.2);
            box-shadow: 0 0 15px rgba(255, 82, 143, 0.1);
        }
        .feature-card h3 {
            font-size: 20px;
            font-weight: 600;
            margin-bottom: 12px;
            color: #FFF;
        }
        .feature-card p {
            font-size: 14px;
            color: #A1A1AA;
            line-height: 1.6;
        }
        @media (max-width: 768px) {
            .hero-text {
                padding-right: 0;
                text-align: center;
                margin-bottom: 40px;
            }
            .hero-text h1 {
                font-size: 42px;
            }
            .hero-text div {
                justify-content: center;
            }
            .hero-img {
                width: 100%;
            }
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
                <h1>Atur Keuangan Praktis,<br><span>Cerdas dengan AI</span></h1>
                <p>Danaku adalah asisten pencatat keuangan pribadi pintar berbasis mobile yang dilengkapi dengan kecerdasan buatan (Speech-to-Text & Vision OCR). Catat pemasukan, pantau tagihan rutin, kelola batas anggaran bulanan, dan cadangkan data secara real-time ke Awan.</p>
                <div style="display: flex; gap: 15px; flex-wrap: wrap;">
                    <a href="/login" class="btn-portal btn-portal-primary" style="padding: 14px 32px;"><i class="fa-solid fa-arrow-right-to-bracket"></i> Masuk Panel Admin</a>
                </div>
            </div>
            <div class="hero-img">
                <div class="glow-bg"></div>
                <div class="phone-mockup">
                    <img src="https://images.unsplash.com/photo-1559526324-4b87b5e36e44?auto=format&fit=crop&q=80&w=600" alt="Financial Charts Mockup">
                    <h3>Danaku App</h3>
                    <p>Sistem Asisten Pengatur Keuangan Premium Terintegrasi AI</p>
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
