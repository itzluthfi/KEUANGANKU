@extends('admin.layout')

@section('title', 'Detail Transaksi - ' . $user->name)
@section('header_title', 'Detail Transaksi')
@section('header_subtitle', 'Analisa ledger keuangan lengkap untuk pengguna ' . $user->name)

@section('content')
<style>
    .btn-back {
        background: #FFF;
        color: #FF528F;
        border: 1px solid rgba(255, 82, 143, 0.2);
        padding: 10px 20px;
        border-radius: 12px;
        font-weight: 600;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 8px;
        font-size: 13px;
        margin-bottom: 25px;
        transition: all 0.3s ease;
    }
    .btn-back:hover {
        background: #FF528F;
        color: white;
        transform: translateX(-3px);
    }

    /* Stats Grid */
    .summary-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
        gap: 20px;
        margin-bottom: 30px;
    }
    .summary-card {
        background: white;
        padding: 24px;
        border-radius: 20px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.02);
        border: 1px solid rgba(0, 0, 0, 0.03);
    }
    .summary-title {
        font-size: 12px;
        color: #888;
        font-weight: 600;
        text-transform: uppercase;
        margin-bottom: 8px;
        letter-spacing: 0.5px;
    }
    .summary-value {
        font-size: 24px;
        font-weight: 800;
    }

    /* Layout structure */
    .detail-row {
        display: flex;
        flex-wrap: wrap;
        gap: 20px;
    }
    .detail-col-lg {
        flex: 2;
        min-width: 500px;
    }
    .detail-col-sm {
        flex: 1;
        min-width: 300px;
    }

    /* Filters bar */
    .filter-bar {
        display: flex;
        flex-wrap: wrap;
        gap: 12px;
        margin-bottom: 20px;
        align-items: center;
    }
    .search-input {
        flex: 1;
        min-width: 200px;
        padding: 10px 16px;
        border-radius: 12px;
        border: 1px solid #E0E0E0;
        font-size: 13px;
        outline: none;
        transition: all 0.3s ease;
    }
    .search-input:focus {
        border-color: #FF528F;
        box-shadow: 0 0 10px rgba(255, 82, 143, 0.1);
    }
    .filter-select {
        padding: 10px 16px;
        border-radius: 12px;
        border: 1px solid #E0E0E0;
        font-size: 13px;
        outline: none;
        background: white;
    }
    .filter-btn {
        padding: 10px 16px;
        border-radius: 12px;
        border: 1px solid #E0E0E0;
        background: white;
        color: #666;
        font-size: 13px;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.3s ease;
    }
    .filter-btn.active {
        background: #FF528F;
        color: white;
        border-color: #FF528F;
    }

    /* Transactions list */
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
    
    .badge-in { background: #E8F5E9; color: #2E7D32; }
    .badge-out { background: #FFEBEE; color: #C62828; }
</style>

<a href="{{ route('admin.users') }}" class="btn-back"><i class="fa-solid fa-arrow-left"></i> Kembali ke Daftar Pengguna</a>

<!-- Kartu Ringkasan -->
<div class="summary-grid">
    <div class="summary-card" style="border-left: 5px solid #2ECC71;">
        <div class="summary-title">Total Pemasukan</div>
        <div class="summary-value" style="color: #2ECC71;">Rp {{ number_format($totalIncome) }}</div>
    </div>
    <div class="summary-card" style="border-left: 5px solid #E74C3C;">
        <div class="summary-title">Total Pengeluaran</div>
        <div class="summary-value" style="color: #E74C3C;">Rp {{ number_format($totalExpense) }}</div>
    </div>
    @php
        $balance = $totalIncome - $totalExpense;
        $balanceColor = $balance >= 0 ? '#2ECC71' : '#E74C3C';
    @endphp
    <div class="summary-card" style="border-left: 5px solid {{ $balanceColor }};">
        <div class="summary-title">Selisih Bersih (Saldo)</div>
        <div class="summary-value" style="color: {{ $balanceColor }};">Rp {{ number_format($balance) }}</div>
    </div>
    <div class="summary-card" style="border-left: 5px solid #FF528F;">
        <div class="summary-title">Jumlah Catatan</div>
        <div class="summary-value" style="color: #FF528F;">{{ count($transactions) }} Transaksi</div>
    </div>
</div>

<div class="detail-row">
    <!-- Tabel ledger transaksi -->
    <div class="detail-col-lg">
        <div class="card-panel">
            <div class="card-panel-title"><i class="fa-solid fa-file-invoice-dollar" style="color:#FF528F;"></i> Jurnal Mutasi Finansial</div>
            
            @if(empty($transactions))
                <div style="text-align:center; padding: 40px; color:#999; font-size:14px;">Belum ada riwayat transaksi yang tersinkronisasi.</div>
            @else
                <!-- Filter Bar -->
                <div class="filter-bar">
                    <input type="text" id="searchInput" class="search-input" placeholder="Cari keterangan atau dompet..." onkeyup="filterLedger()">
                    <select id="categoryFilter" class="filter-select" onchange="filterLedger()">
                        <option value="">Semua Kategori</option>
                        @foreach(array_unique(array_column($transactions, 'kategori')) as $cat)
                            @if($cat) <option value="{{ $cat }}">{{ $cat }}</option> @endif
                        @endforeach
                    </select>
                    <button class="filter-btn active" onclick="setJenisFilter('all', this)">Semua</button>
                    <button class="filter-btn" onclick="setJenisFilter('masuk', this)">Masuk</button>
                    <button class="filter-btn" onclick="setJenisFilter('keluar', this)">Keluar</button>
                </div>

                <div style="overflow-x:auto;">
                    <table id="ledgerTable">
                        <thead>
                            <tr>
                                <th>Tanggal</th>
                                <th>Keterangan</th>
                                <th>Kategori</th>
                                <th>Dompet</th>
                                <th>Tipe</th>
                                <th>Jumlah</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($transactions as $t)
                                @php
                                    $jenis = strtolower($t['jenis'] ?? 'keluar');
                                @endphp
                                <tr class="ledger-row" data-jenis="{{ $jenis }}" data-kategori="{{ $t['kategori'] ?? '' }}">
                                    <td>{{ $t['tanggal'] ?? '-' }}</td>
                                    <td><strong class="ledger-desc">{{ $t['keterangan'] ?? '-' }}</strong></td>
                                    <td><span style="font-weight: 600; color: #888;">{{ $t['kategori'] ?? 'Harian' }}</span></td>
                                    <td><span class="ledger-wallet" style="color: #FF528F; font-weight: 600;"><i class="fa-solid fa-wallet"></i> {{ $t['walletNama'] ?? 'Utama' }}</span></td>
                                    <td>
                                        <span class="badge {{ $jenis === 'masuk' ? 'badge-in' : 'badge-out' }}">
                                            {{ $jenis }}
                                        </span>
                                    </td>
                                    <td>
                                        <strong style="color: {{ $jenis === 'masuk' ? '#2ECC71' : '#E74C3C' }}">
                                            Rp {{ number_format((int) ($t['jumlah'] ?? 0)) }}
                                        </strong>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endif
        </div>
    </div>

    <!-- Statistik Donut Kategori Pengeluaran Terbesar User -->
    <div class="detail-col-sm">
        <div class="card-panel">
            <div class="card-panel-title"><i class="fa-solid fa-chart-pie" style="color:#FF528F;"></i> Alokasi Pengeluaran</div>
            @if(empty($categoryLabels))
                <div style="text-align:center; padding: 60px 20px; color:#999; font-size:13px;">Belum ada pengeluaran terekam.</div>
            @else
                <div style="height:250px; display:flex; justify-content:center;">
                    <canvas id="userCategoryChart" style="max-height: 250px;"></canvas>
                </div>
                <script>
                    new Chart(document.getElementById('userCategoryChart').getContext('2d'), {
                        type: 'doughnut',
                        data: {
                            labels: {!! json_encode($categoryLabels) !!},
                            datasets: [{
                                data: {!! json_encode($categoryValues) !!},
                                backgroundColor: ['#E74C3C', '#E67E22', '#F1C40F', '#9B59B6', '#34495E'],
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
</div>
@endsection

@section('scripts')
<script>
    let activeJenisFilter = 'all';

    function setJenisFilter(jenis, btn) {
        document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        
        activeJenisFilter = jenis;
        filterLedger();
    }

    function filterLedger() {
        const searchQuery = document.getElementById('searchInput').value.toLowerCase();
        const selectedCategory = document.getElementById('categoryFilter').value;
        const rows = document.querySelectorAll('.ledger-row');

        rows.forEach(row => {
            const description = row.querySelector('.ledger-desc').textContent.toLowerCase();
            const wallet = row.querySelector('.ledger-wallet').textContent.toLowerCase();
            const category = row.getAttribute('data-kategori');
            const jenis = row.getAttribute('data-jenis');

            const matchesText = description.includes(searchQuery) || wallet.includes(searchQuery);
            const matchesCategory = selectedCategory === "" || category === selectedCategory;
            const matchesJenis = activeJenisFilter === 'all' || jenis === activeJenisFilter;

            if (matchesText && matchesCategory && matchesJenis) {
                row.style.display = '';
            } else {
                row.style.display = 'none';
            }
        });
    }
</script>
@endsection
