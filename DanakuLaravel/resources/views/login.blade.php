<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login Administrator - Danaku</title>
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
                radial-gradient(at 100% 100%, rgba(74, 144, 226, 0.08) 0, transparent 50%),
                linear-gradient(rgba(255, 255, 255, 0.007) 1px, transparent 1px),
                linear-gradient(90deg, rgba(255, 255, 255, 0.007) 1px, transparent 1px);
            background-size: 100% 100%, 100% 100%, 40px 40px, 40px 40px;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            color: #F4F4F5;
            position: relative;
            overflow: hidden;
        }
        .glow-bg {
            position: absolute;
            width: 400px;
            height: 400px;
            background: radial-gradient(circle, rgba(255, 82, 143, 0.12) 0%, rgba(74, 144, 226, 0.06) 60%, transparent 100%);
            filter: blur(60px);
            z-index: 1;
            pointer-events: none;
        }
        .login-card {
            background: rgba(20, 20, 28, 0.6);
            backdrop-filter: blur(24px);
            padding: 48px 40px;
            border-radius: 36px;
            box-shadow: 
                0 30px 60px rgba(0, 0, 0, 0.4), 
                inset 0 1px 0 rgba(255, 255, 255, 0.08);
            width: 100%;
            max-width: 440px;
            border: 1px solid rgba(255, 255, 255, 0.08);
            z-index: 10;
            position: relative;
        }
        .logo {
            font-size: 28px;
            font-weight: 800;
            color: #FFF;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 12px;
            margin-bottom: 36px;
            letter-spacing: -0.5px;
        }
        .logo i {
            color: #FF528F;
            filter: drop-shadow(0 0 8px rgba(255, 82, 143, 0.5));
            font-size: 30px;
        }
        .input-group {
            margin-bottom: 24px;
            position: relative;
        }
        .input-group label {
            display: block;
            font-size: 11px;
            font-weight: 700;
            color: #A1A1AA;
            margin-bottom: 10px;
            letter-spacing: 0.8px;
        }
        .input-group input {
            width: 100%;
            padding: 14px 18px;
            border-radius: 16px;
            border: 1px solid rgba(255, 255, 255, 0.08);
            font-size: 14px;
            outline: none;
            transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
            background: rgba(255, 255, 255, 0.02);
            color: #FFF;
        }
        .input-group input::placeholder {
            color: #52525B;
        }
        .input-group input:focus {
            border-color: rgba(255, 82, 143, 0.5);
            background: rgba(255, 255, 255, 0.05);
            box-shadow: 0 0 15px rgba(255, 82, 143, 0.15);
        }
        .btn-login {
            width: 100%;
            background: linear-gradient(135deg, #FF528F 0%, #FF7A9F 100%);
            color: white;
            border: none;
            padding: 16px;
            border-radius: 16px;
            font-size: 15px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
            margin-top: 10px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            box-shadow: 0 0 20px rgba(255, 82, 143, 0.25);
        }
        .btn-login:hover {
            background: linear-gradient(135deg, #FF7A9F 0%, #FF9EBA 100%);
            transform: translateY(-2px);
            box-shadow: 0 0 30px rgba(255, 82, 143, 0.45);
        }
        .error-box {
            background: rgba(239, 68, 68, 0.1);
            border: 1px solid rgba(239, 68, 68, 0.3);
            padding: 14px;
            border-radius: 16px;
            color: #F87171;
            font-size: 13px;
            margin-bottom: 24px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .error-box i {
            font-size: 16px;
        }
        .back-link {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            justify-content: center;
            width: 100%;
            margin-top: 30px;
            font-size: 13px;
            color: #A1A1AA;
            text-decoration: none;
            font-weight: 600;
            transition: color 0.2s ease;
        }
        .back-link:hover {
            color: #FF528F;
        }
    </style>
</head>
<body>
    <div class="glow-bg"></div>

    <div class="login-card">
        <div class="logo">
            <i class="fa-solid fa-piggy-bank"></i>
            <span>Danaku</span>
        </div>

        @if ($errors->any())
            <div class="error-box">
                <i class="fa-solid fa-circle-exclamation"></i>
                <span>{{ $errors->first() }}</span>
            </div>
        @endif

        @if (session('error'))
            <div class="error-box">
                <i class="fa-solid fa-circle-exclamation"></i>
                <span>{{ session('error') }}</span>
            </div>
        @endif

        <form action="/login" method="POST">
            @csrf
            <div class="input-group">
                <label for="email">EMAIL ADMINISTRATOR</label>
                <input type="email" id="email" name="email" placeholder="admin@danaku.id" required autofocus>
            </div>
            <div class="input-group">
                <label for="password">PASSWORD</label>
                <input type="password" id="password" name="password" placeholder="••••••••" required>
            </div>
            <button type="submit" class="btn-login"><i class="fa-solid fa-right-to-bracket"></i> Masuk Panel</button>
        </form>

        <a href="/" class="back-link"><i class="fa-solid fa-arrow-left"></i> Kembali ke Beranda</a>
    </div>
</body>
</html>
