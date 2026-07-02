<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login Administrator - Danaku</title>
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
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .login-card {
            background: white;
            padding: 40px;
            border-radius: 30px;
            box-shadow: 0 20px 40px rgba(255, 82, 143, 0.1);
            width: 100%;
            max-width: 420px;
            border: 1px solid rgba(255, 82, 143, 0.1);
        }
        .logo {
            font-size: 26px;
            font-weight: 800;
            color: #FF528F;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            margin-bottom: 30px;
        }
        .logo i {
            font-size: 30px;
        }
        .input-group {
            margin-bottom: 20px;
            position: relative;
        }
        .input-group label {
            display: block;
            font-size: 13px;
            font-weight: 600;
            color: #666;
            margin-bottom: 8px;
        }
        .input-group input {
            width: 100%;
            padding: 12px 16px;
            border-radius: 15px;
            border: 1px solid #FFE4E1;
            font-size: 14px;
            outline: none;
            transition: all 0.3s ease;
            background: #FAFAFA;
        }
        .input-group input:focus {
            border-color: #FF528F;
            background: white;
            box-shadow: 0 0 10px rgba(255, 82, 143, 0.1);
        }
        .btn-login {
            width: 100%;
            background: #FF528F;
            color: white;
            border: none;
            padding: 14px;
            border-radius: 15px;
            font-size: 15px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            margin-top: 10px;
        }
        .btn-login:hover {
            background: #FF7A9F;
            transform: translateY(-1px);
            box-shadow: 0 8px 20px rgba(255, 82, 143, 0.2);
        }
        .error-box {
            background: #FFEBEE;
            border: 1px solid #FFCDD2;
            padding: 12px;
            border-radius: 15px;
            color: #C62828;
            font-size: 13px;
            margin-bottom: 20px;
        }
        .back-link {
            display: block;
            text-align: center;
            margin-top: 25px;
            font-size: 13px;
            color: #FF528F;
            text-decoration: none;
            font-weight: 600;
        }
        .back-link:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="login-card">
        <div class="logo">
            <i class="fa-solid fa-piggy-bank"></i>
            <span>Danaku</span>
        </div>

        @if ($errors->any())
            <div class="error-box">
                <i class="fa-solid fa-circle-exclamation"></i> {{ $errors->first() }}
            </div>
        @endif

        @if (session('error'))
            <div class="error-box">
                <i class="fa-solid fa-circle-exclamation"></i> {{ session('error') }}
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
