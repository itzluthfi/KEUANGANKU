@extends('admin.layout')

@section('title', 'Finansial Global')
@section('header_title', 'Finansial Global')
@section('header_subtitle', 'Statistik gabungan transaksi dan dompet pengguna Danaku.')

@section('content')
<style>
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

    /* Charts Row */
    .charts-row {
        display: flex;
        flex-wrap: wrap;
        gap: 20px;
        margin-bottom: 30px;
    }
    .chart-card {
        flex: 1;
        min-width: 320px;
        background: white;
        padding: 24px;
        border-radius: 20px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.02);
        border: 1px solid rgba(0, 0, 0, 0.03);
    }

    /* Table Styling */
    table {
        width: 100%;
        border-collapse: collapse;
    }
    th, td {
        text-align: left;
        padding: 14px;
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
</style>

<!-- Metrik Cepat -->
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
            <h3>Cadangan Awan</h3>
            <p>{{ $totalBackups }}</p>
        </div>
        <div class="stat-icon" style="background:#FFF3E0; color:#F57C00;"><i class="fa-solid fa-cloud-arrow-up"></i></div>
    </div>
    <div class="stat-card">
        <div class="stat-info">
            <h3>Transaksi Tercatat</h3>
            <p>{{ number_format($totalTransactions) }}</p>
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

<!-- Grafik Finansial Global -->
<div class="charts-row">
    <!-- Chart Kategori Paling Populer -->
    <div class="chart-card">
        <div class="card-panel-title"><i class="fa-solid fa-tags" style="color:#FF528F;"></i> Kategori Pengeluaran Terpopuler (Global)</div>
        @if(empty($categoryLabels))
            <div style="text-align:center; padding: 60px 20px; color:#999; font-size:13px;">Belum ada data transaksi yang di-backup.</div>
        @else
            <div style="height:250px; display:flex; justify-content:center;">
                <canvas id="categoryChart" style="max-height: 250px;"></canvas>
            </div>
            <script>
                new Chart(document.getElementById('categoryChart').getContext('2d'), {
                    type: 'doughnut',
                    data: {
                        labels: {!! json_encode($categoryLabels) !!},
                        datasets: [{
                            data: {!! json_encode($categoryValues) !!},
                            backgroundColor: ['#FF528F', '#4A90E2', '#50E3C2', '#F5A623', '#9B51E0'],
                            borderWidth: 2
                        }]
                    },
                    options: {
                        responsive: true,
                        plugins: {
                            legend: {
                                position: 'bottom',
                                labels: { font: { family: 'Outfit', size: 11 } }
                            }
                        }
                    }
                });
            </script>
        @endif
    </div>

    <!-- Chart Dompet Terpopuler -->
    <div class="chart-card">
        <div class="card-panel-title"><i class="fa-solid fa-wallet" style="color:#FF528F;"></i> Distribusi E-Wallet Aktif</div>
        @if(empty($walletLabels))
            <div style="text-align:center; padding: 60px 20px; color:#999; font-size:13px;">Belum ada data dompet yang di-backup.</div>
        @else
            <div style="height:250px; display:flex; justify-content:center;">
                <canvas id="walletChart" style="max-height: 250px;"></canvas>
            </div>
            <script>
                new Chart(document.getElementById('walletChart').getContext('2d'), {
                    type: 'pie',
                    data: {
                        labels: {!! json_encode($walletLabels) !!},
                        datasets: [{
                            data: {!! json_encode($walletValues) !!},
                            backgroundColor: ['#2ECC71', '#3498DB', '#9B59B6', '#E67E22', '#F1C40F'],
                            borderWidth: 2
                        }]
                    },
                    options: {
                        responsive: true,
                        plugins: {
                            legend: {
                                position: 'bottom',
                                labels: { font: { family: 'Outfit', size: 11 } }
                            }
                        }
                    }
                });
            </script>
        @endif
    </div>
</div>

<!-- Log Sinkronisasi Terbaru -->
<div class="card-panel">
    <div class="card-panel-title"><i class="fa-solid fa-sync" style="color:#FF528F;"></i> Antrean Sinkronisasi Cadangan Terbaru</div>
    @if($recentSyncs->isEmpty())
        <div style="text-align:center; padding: 40px; color:#999; font-size:14px;">Belum ada riwayat pencadangan data di server.</div>
    @else
        <table>
            <thead>
                <tr>
                    <th>Pengguna</th>
                    <th>Email</th>
                    <th>Status Koneksi</th>
                    <th>Pembaruan Terakhir</th>
                </tr>
            </thead>
            <tbody>
                @foreach($recentSyncs as $sync)
                    <tr>
                        <td><strong>{{ $sync->user ? $sync->user->name : 'N/A' }}</strong></td>
                        <td>{{ $sync->user ? $sync->user->email : 'N/A' }}</td>
                        <td><span class="badge badge-success">Online & Synced</span></td>
                        <td>{{ $sync->updated_at->diffForHumans() }}</td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    @endif
</div>
@endsection
