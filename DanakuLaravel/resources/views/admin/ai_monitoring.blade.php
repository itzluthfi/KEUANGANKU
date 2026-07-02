@extends('admin.layout')

@section('title', 'Monitoring Token AI')
@section('header_title', 'Monitoring Token AI')
@section('header_subtitle', 'Analisa waktu respons, status pemanggilan, dan sisa limit harian model AI.')

@section('content')
<style>
    /* AI Quota Grid */
    .quota-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
        gap: 20px;
        margin-bottom: 30px;
    }
    .quota-card {
        background: white;
        padding: 24px;
        border-radius: 20px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.02);
        border: 1px solid rgba(0, 0, 0, 0.03);
    }
    .quota-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 15px;
    }
    .quota-name {
        font-weight: 800;
        font-size: 16px;
        color: #333;
    }
    .quota-bar-bg {
        background: #F0F0F0;
        height: 8px;
        border-radius: 4px;
        overflow: hidden;
        margin-bottom: 12px;
    }
    .quota-bar-fill {
        height: 100%;
        border-radius: 4px;
        transition: width 0.5s ease;
    }
    .quota-footer {
        display: flex;
        justify-content: space-between;
        font-size: 11px;
        color: #888;
        font-weight: 600;
    }

    /* Charts row */
    .charts-row {
        display: flex;
        flex-wrap: wrap;
        gap: 20px;
        margin-bottom: 30px;
    }
    .chart-card-lg {
        flex: 2;
        min-width: 500px;
        background: white;
        padding: 24px;
        border-radius: 20px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.02);
        border: 1px solid rgba(0, 0, 0, 0.03);
    }
    .chart-card-sm {
        flex: 1;
        min-width: 300px;
        background: white;
        padding: 24px;
        border-radius: 20px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.02);
        border: 1px solid rgba(0, 0, 0, 0.03);
    }

    /* Table & Log List */
    table {
        width: 100%;
        border-collapse: collapse;
    }
    th, td {
        text-align: left;
        padding: 12px 14px;
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
    
    .pagination {
        display: flex;
        list-style: none;
        gap: 8px;
        justify-content: center;
        margin-top: 20px;
    }
    .pagination li a, .pagination li span {
        padding: 8px 14px;
        border-radius: 8px;
        background: white;
        color: #FF528F;
        text-decoration: none;
        font-weight: 600;
        font-size: 12px;
        border: 1px solid rgba(255, 82, 143, 0.1);
    }
    .pagination li.active span {
        background: #FF528F;
        color: white;
    }
</style>

<!-- Quota Cards -->
<div class="quota-grid">
    <!-- Gemini -->
    <div class="quota-card">
        <div class="quota-header">
            <span class="quota-name">Google Gemini 2.5</span>
            <span class="provider-pill provider-gemini">Limit Harian</span>
        </div>
        <div style="font-size:22px; font-weight:800; margin-bottom:10px;">
            {{ $usageToday['gemini'] }} <span style="font-size:13px; color:#aaa; font-weight:600;">/ {{ $limits['gemini'] }} Req</span>
        </div>
        @php
            $geminiPercent = min(100, ($usageToday['gemini'] / $limits['gemini']) * 100);
            $geminiColor = $geminiPercent > 80 ? '#D32F2F' : ($geminiPercent > 50 ? '#F57C00' : '#E24C80');
        @endphp
        <div class="quota-bar-bg">
            <div class="quota-bar-fill" style="width: {{ $geminiPercent }}%; background: {{ $geminiColor }};"></div>
        </div>
        <div class="quota-footer">
            <span>Sisa Kuota: {{ number_format($remainingQuota['gemini']) }}</span>
            <span>Speed: {{ $latencyAvg['gemini'] }} ms</span>
        </div>
    </div>

    <!-- Groq -->
    <div class="quota-card">
        <div class="quota-header">
            <span class="quota-name">Groq Qwen 2.5</span>
            <span class="provider-pill provider-groq">Limit Harian</span>
        </div>
        <div style="font-size:22px; font-weight:800; margin-bottom:10px;">
            {{ $usageToday['groq'] }} <span style="font-size:13px; color:#aaa; font-weight:600;">/ {{ $limits['groq'] }} Req</span>
        </div>
        @php
            $groqPercent = min(100, ($usageToday['groq'] / $limits['groq']) * 100);
            $groqColor = $groqPercent > 80 ? '#D32F2F' : ($groqPercent > 50 ? '#F57C00' : '#4A90E2');
        @endphp
        <div class="quota-bar-bg">
            <div class="quota-bar-fill" style="width: {{ $groqPercent }}%; background: {{ $groqColor }};"></div>
        </div>
        <div class="quota-footer">
            <span>Sisa Kuota: {{ number_format($remainingQuota['groq']) }}</span>
            <span>Speed: {{ $latencyAvg['groq'] }} ms</span>
        </div>
    </div>

    <!-- Nvidia -->
    <div class="quota-card">
        <div class="quota-header">
            <span class="quota-name">Nvidia Llama 3.2</span>
            <span class="provider-pill provider-nvidia">Limit Harian</span>
        </div>
        <div style="font-size:22px; font-weight:800; margin-bottom:10px;">
            {{ $usageToday['nvidia'] }} <span style="font-size:13px; color:#aaa; font-weight:600;">/ {{ $limits['nvidia'] }} Req</span>
        </div>
        @php
            $nvidiaPercent = min(100, ($usageToday['nvidia'] / $limits['nvidia']) * 100);
            $nvidiaColor = $nvidiaPercent > 80 ? '#D32F2F' : ($nvidiaPercent > 50 ? '#F57C00' : '#2ECC71');
        @endphp
        <div class="quota-bar-bg">
            <div class="quota-bar-fill" style="width: {{ $nvidiaPercent }}%; background: {{ $nvidiaColor }};"></div>
        </div>
        <div class="quota-footer">
            <span>Sisa Kuota: {{ number_format($remainingQuota['nvidia']) }}</span>
            <span>Speed: {{ $latencyAvg['nvidia'] }} ms</span>
        </div>
    </div>
</div>

<!-- Latency & Success rate Charts -->
<div class="charts-row">
    <!-- Latency Line Chart -->
    <div class="chart-card-lg">
        <div class="card-panel-title"><i class="fa-solid fa-gauge-high" style="color:#FF528F;"></i> Waktu Respons Panggilan AI Terbaru (Latency)</div>
        @if(empty($chartLabels))
            <div style="text-align:center; padding: 60px 20px; color:#999; font-size:13px;">Belum ada panggilan AI yang terekam.</div>
        @else
            <div style="height:250px;">
                <canvas id="latencyChart"></canvas>
            </div>
            <script>
                new Chart(document.getElementById('latencyChart').getContext('2d'), {
                    type: 'line',
                    data: {
                        labels: {!! json_encode($chartLabels) !!},
                        datasets: [{
                            label: 'Latency (ms)',
                            data: {!! json_encode($chartLatencies) !!},
                            borderColor: '#FF528F',
                            backgroundColor: 'rgba(255, 82, 143, 0.05)',
                            fill: true,
                            tension: 0.3,
                            borderWidth: 3,
                            pointBackgroundColor: '#FF528F'
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: { legend: { display: false } },
                        scales: {
                            y: { beginAtZero: true, grid: { color: '#F0F0F0' }, ticks: { font: { family: 'Outfit' } } },
                            x: { grid: { display: false }, ticks: { font: { family: 'Outfit' } } }
                        }
                    }
                });
            </script>
        @endif
    </div>

    <!-- Success rate Pie -->
    <div class="chart-card-sm">
        <div class="card-panel-title"><i class="fa-solid fa-square-check" style="color:#FF528F;"></i> Kehandalan API AI</div>
        <div style="height:250px; display:flex; justify-content:center;">
            <canvas id="successChart" style="max-height: 250px;"></canvas>
        </div>
        <script>
            // Hitung rata-rata sukses/gagal secara global
            @php
                $successCount = $allLogs->where('status', 'success')->count();
                $failedCount = $allLogs->where('status', 'failed')->count();
            @endphp
            new Chart(document.getElementById('successChart').getContext('2d'), {
                type: 'pie',
                data: {
                    labels: ['Sukses', 'Gagal'],
                    datasets: [{
                        data: [{{ $successCount }}, {{ $failedCount }}],
                        backgroundColor: ['#2ECC71', '#E74C3C'],
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
    </div>
</div>

<!-- History log -->
<div class="card-panel">
    <div class="card-panel-title"><i class="fa-solid fa-list-check" style="color:#FF528F;"></i> Jurnal Riwayat Log Panggilan AI</div>
    @if($allLogs->isEmpty())
        <div style="text-align:center; padding: 40px; color:#999; font-size:14px;">Belum ada transaksi log panggilan AI terekam.</div>
    @else
        <table>
            <thead>
                <tr>
                    <th>Waktu</th>
                    <th>User</th>
                    <th>Fitur</th>
                    <th>Model</th>
                    <th>Status</th>
                    <th>Latency</th>
                    <th>Pesan Error</th>
                    <th>Respon AI</th>
                </tr>
            </thead>
            <tbody>
                @foreach($allLogs as $log)
                    <tr>
                        <td>{{ $log->created_at->format('d/m/y H:i:s') }}</td>
                        <td><strong>{{ $log->user ? $log->user->name : 'Guest User' }}</strong></td>
                        <td><span class="badge {{ $log->feature === 'stt' ? 'badge-stt' : 'badge-ocr' }}">{{ strtoupper($log->feature) }}</span></td>
                        <td><span class="provider-pill provider-{{ strtolower($log->provider) }}">{{ $log->model_name ?? $log->provider }}</span></td>
                        <td><span class="badge {{ $log->status === 'success' ? 'badge-success' : 'badge-danger' }}">{{ $log->status }}</span></td>
                        <td><strong>{{ number_format($log->latency_ms) }} ms</strong></td>
                        <td style="color:#C62828; font-family: monospace; font-size: 11px;">
                            {{ $log->error_message ? Str::limit($log->error_message, 45) : '-' }}
                        </td>
                        <td>
                            @if($log->response_content)
                                <span style="cursor: pointer; text-decoration: underline; color: #1E88E5; font-family: monospace; font-size: 11px;" 
                                      onclick="showResponseModal(this)" 
                                      data-response="{{ $log->response_content }}">
                                    {{ Str::limit($log->response_content, 35) }}
                                </span>
                            @else
                                -
                            @endif
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>
        
        <!-- Pagination -->
        <div style="display:flex; justify-content:center;">
            {{ $allLogs->links() }}
        </div>
    @endif
</div>

<script>
function showResponseModal(element) {
    const rawJson = element.getAttribute('data-response');
    let formattedJson = rawJson;
    try {
        const parsed = JSON.parse(rawJson);
        formattedJson = JSON.stringify(parsed, null, 4);
    } catch (e) {
        // Not JSON
    }
    
    Swal.fire({
        title: 'Detail Respon AI',
        html: '<pre style="text-align: left; background: #f4f6f7; padding: 12px; border-radius: 8px; font-size: 11px; overflow-x: auto; max-height: 400px; font-family: monospace; white-space: pre-wrap; word-wrap: break-word;">' + 
              escapeHtml(formattedJson) + 
              '</pre>',
        confirmButtonText: 'Tutup',
        confirmButtonColor: '#FF528F',
        width: '600px'
    });
}

function escapeHtml(text) {
    return text
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}
</script>
@endsection
