<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Administrator - Danaku</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Outfit', sans-serif;
        }
        body {
            background-color: #F4F7F6;
            color: #333;
            display: flex;
            min-height: 100vh;
        }
        
        /* Sidebar */
        .sidebar {
            width: 260px;
            background: linear-gradient(180deg, #FF528F 0%, #FF7A9F 100%);
            color: white;
            padding: 30px 20px;
            display: flex;
            flex-direction: column;
            box-shadow: 4px 0 15px rgba(255, 82, 143, 0.1);
        }
        .sidebar-brand {
            font-size: 24px;
            font-weight: 800;
            margin-bottom: 40px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .sidebar-menu {
            list-style: none;
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        .sidebar-menu li a {
            display: flex;
            align-items: center;
            gap: 15px;
            color: rgba(255, 255, 255, 0.85);
            text-decoration: none;
            padding: 12px 16px;
            border-radius: 15px;
            font-weight: 600;
            font-size: 14px;
            transition: all 0.3s ease;
        }
        .sidebar-menu li.active a, .sidebar-menu li a:hover {
            background: white;
            color: #FF528F;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.05);
        }
        
        /* Main Content */
        .main-content {
            flex: 1;
            padding: 40px;
            overflow-y: auto;
            max-width: calc(100% - 260px);
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
        }
        .header h1 {
            font-size: 28px;
            font-weight: 800;
            color: #333;
        }
        .btn-logout {
            background: #FFCDD2;
            color: #C62828;
            border: none;
            padding: 10px 20px;
            border-radius: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .btn-logout:hover {
            background: #C62828;
            color: white;
        }
        
        /* Stats Grid */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: white;
            padding: 24px;
            border-radius: 20px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.02);
            border: 1px solid rgba(0, 0, 0, 0.03);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .stat-info h3 {
            font-size: 13px;
            color: #888;
            font-weight: 600;
            margin-bottom: 6px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .stat-info p {
            font-size: 24px;
            font-weight: 800;
            color: #333;
        }
        .stat-icon {
            width: 50px;
            height: 50px;
            border-radius: 15px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 22px;
        }
        
        /* Dashboard Cards & Layout */
        .dashboard-row {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
            margin-bottom: 30px;
        }
        .card-lg {
            flex: 2;
            min-width: 500px;
            background: white;
            padding: 24px;
            border-radius: 20px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.02);
            border: 1px solid rgba(0, 0, 0, 0.03);
        }
        .card-sm {
            flex: 1;
            min-width: 300px;
            background: white;
            padding: 24px;
            border-radius: 20px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.02);
            border: 1px solid rgba(0, 0, 0, 0.03);
        }
        .card-title {
            font-size: 16px;
            font-weight: 700;
            margin-bottom: 20px;
            color: #333;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        /* Table Styling */
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            text-align: left;
            padding: 12px;
            font-size: 13px;
        }
        th {
            background-color: #FAFAFA;
            color: #666;
            font-weight: 600;
            border-bottom: 2px solid #EEE;
        }
        td {
            border-bottom: 1px solid #F5F5F5;
            color: #444;
        }
        tr:hover td {
            background-color: #FAFAFA;
        }
        
        .badge {
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 10px;
            font-weight: 800;
            text-transform: uppercase;
        }
        .badge-stt { background: #E8F5E9; color: #2E7D32; }
        .badge-ocr { background: #E3F2FD; color: #1565C0; }
        
        .provider-pill {
            padding: 3px 8px;
            border-radius: 8px;
            font-size: 10px;
            font-weight: 700;
            color: white;
        }
        .provider-gemini { background-color: #E24C80; }
        .provider-groq { background-color: #4A90E2; }
        .provider-nvidia { background-color: #2ECC71; }
    </style>
</head>
<body>
    <!-- Sidebar -->
    <div class="sidebar">
        <div class="sidebar-brand">
            <i class="fa-solid fa-piggy-bank"></i>
            <span>Danaku Admin</span>
        </div>
        <ul class="sidebar-menu">
            <li class="active"><a href="#"><i class="fa-solid fa-chart-line"></i> Dashboard</a></li>
        </ul>
    </div>

    <!-- Main Content -->
    <div class="main-content">
        <div class="header">
            <div>
                <h1>Ringkasan Aktivitas</h1>
                <p style="font-size:13px; color:#888;">Selamat datang kembali di panel kendali DanakuApp.</p>
            </div>
            <form action="{{ route('logout') }}" method="POST">
                @csrf
                <button type="submit" class="btn-logout"><i class="fa-solid fa-right-from-bracket"></i> Keluar</button>
            </form>
        </div>

        <!-- Metrik Utama -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-info">
                    <h3>Total Pengguna</h3>
                    <p>{{ $totalUsers }}</p>
                </div>
                <div class="stat-icon" style="background:#E3F2FD; color:#1976D2;"><i class="fa-solid fa-users"></i></div>
            </div>
            <div class="stat-card">
                <div class="stat-info">
                    <h3>Backup Awan</h3>
                    <p>{{ $totalBackups }}</p>
                </div>
                <div class="stat-icon" style="background:#FFF3E0; color:#F57C00;"><i class="fa-solid fa-cloud-arrow-up"></i></div>
            </div>
            <div class="stat-card">
                <div class="stat-info">
                    <h3>Total Transaksi</h3>
                    <p>{{ $totalTransactions }}</p>
                </div>
                <div class="stat-icon" style="background:#E8F5E9; color:#388E3C;"><i class="fa-solid fa-receipt"></i></div>
            </div>
            <div class="stat-card">
                <div class="stat-info">
                    <h3>Request AI Hari Ini</h3>
                    <p>{{ $apiRequestsToday }} / {{ $totalApiRequests }}</p>
                </div>
                <div class="stat-icon" style="background:#FCE4EC; color:#C2185B;"><i class="fa-solid fa-microchip"></i></div>
            </div>
        </div>

        <!-- Grafik & Log Aktivitas -->
        <div class="dashboard-row">
            <!-- 1. Log Penggunaan AI -->
            <div class="card-lg">
                <div class="card-title"><i class="fa-solid fa-history" style="color:#FF528F;"></i> Log Konsumsi AI Terbaru</div>
                @if($recentLogs->isEmpty())
                    <div style="text-align:center; padding: 40px; color:#999; font-size:14px;">Belum ada riwayat aktivitas log AI.</div>
                @else
                    <table>
                        <thead>
                            <tr>
                                <th>User</th>
                                <th>Fitur</th>
                                <th>Provider</th>
                                <th>Karakter/Token</th>
                                <th>Waktu</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($recentLogs as $log)
                                <tr>
                                    <td><strong>{{ $log->user ? $log->user->name : 'Guest User' }}</strong></td>
                                    <td><span class="badge {{ $log->feature === 'stt' ? 'badge-stt' : 'badge-ocr' }}">{{ strtoupper($log->feature) }}</span></td>
                                    <td><span class="provider-pill provider-{{ strtolower($log->provider) }}">{{ $log->provider }}</span></td>
                                    <td>{{ number_format($log->characters_processed) }} token</td>
                                    <td>{{ $log->created_at->diffForHumans() }}</td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                @endif
            </div>

            <!-- 2. Grafik Chart Doughnut Token AI -->
            <div class="card-sm">
                <div class="card-title"><i class="fa-solid fa-chart-pie" style="color:#FF528F;"></i> Distribusi Token AI</div>
                @if(empty($providerLabels))
                    <div style="text-align:center; padding: 80px 40px; color:#999; font-size:14px;">Belum ada pemakaian AI terdeteksi.</div>
                @else
                    <div style="position: relative; height:200px; width:100%; display: flex; justify-content: center;">
                        <canvas id="tokenChart" style="max-height: 200px; max-width: 200px;"></canvas>
                    </div>
                    <script>
                        const ctx = document.getElementById('tokenChart').getContext('2d');
                        new Chart(ctx, {
                            type: 'doughnut',
                            data: {
                                labels: {!! json_encode($providerLabels) !!},
                                datasets: [{
                                    data: {!! json_encode($providerChars) !!},
                                    backgroundColor: {!! json_encode($providerColors) !!},
                                    borderWidth: 2,
                                    borderColor: '#ffffff'
                                }]
                            },
                            options: {
                                responsive: true,
                                plugins: {
                                    legend: {
                                        position: 'bottom',
                                        labels: {
                                            boxWidth: 12,
                                            font: { size: 11, family: 'Outfit' }
                                        }
                                    }
                                }
                            }
                        });
                    </script>
                @endif
            </div>
        </div>

        <!-- List Database Backup Pengguna -->
        <div class="card-lg" style="margin-bottom: 0;">
            <div class="card-title"><i class="fa-solid fa-database" style="color:#FF528F;"></i> Database & Sinkronisasi Pengguna</div>
            @if($usersList->isEmpty())
                <div style="text-align:center; padding: 40px; color:#999; font-size:14px;">Belum ada pengguna terdaftar.</div>
            @else
                <table>
                    <thead>
                        <tr>
                            <th>Nama</th>
                            <th>Email</th>
                            <th>Total Transaksi</th>
                            <th>Ukuran Backup</th>
                            <th>Sinkronisasi Terakhir</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($usersList as $user)
                            <tr>
                                <td><strong>{{ $user['name'] }}</strong></td>
                                <td>{{ $user['email'] }}</td>
                                <td><span style="font-weight:bold; color:#FF528F;">{{ $user['transactions'] }}</span> transaksi</td>
                                <td>{{ $user['backup_size'] }}</td>
                                <td>{{ $user['last_sync'] }}</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            @endif
        </div>
    </div>
</body>
</html>
