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
    .provider-cerebras { background-color: #9B59B6; }
    .provider-groq { background-color: #4A90E2; }
    .provider-cloudflare { background-color: #F38020; }
    .provider-nvidia { background-color: #2ECC71; }
    
    .badge-stt { background-color: #E3F2FD; color: #1565C0; }
    .badge-ocr { background-color: #FCE4EC; color: #C2185B; }
    .badge-advisor { background-color: #E8F5E9; color: #2E7D32; }
    
    /* Token Usage Summary */
    .token-summary {
        display: flex;
        flex-wrap: wrap;
        gap: 20px;
        background: white;
        padding: 24px;
        border-radius: 20px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.02);
        border: 1px solid rgba(0, 0, 0, 0.03);
        margin-bottom: 30px;
    }
    .token-total-box {
        flex: 1;
        min-width: 240px;
        background: linear-gradient(135deg, #FF528F, #FF7A9F);
        border-radius: 16px;
        padding: 24px;
        color: white;
        display: flex;
        flex-direction: column;
        justify-content: center;
    }
    .token-total-box .token-label {
        font-size: 12px;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        opacity: 0.85;
        margin-bottom: 8px;
    }
    .token-total-box .token-value {
        font-size: 32px;
        font-weight: 800;
        line-height: 1.1;
    }
    .token-total-box .token-sub {
        font-size: 11px;
        font-weight: 600;
        opacity: 0.8;
        margin-top: 8px;
    }
    .token-model-list {
        flex: 2;
        min-width: 300px;
        display: flex;
        flex-direction: column;
        justify-content: center;
        gap: 12px;
    }
    .token-model-row .token-model-head {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 5px;
    }
    .token-model-row .token-model-name {
        font-size: 12px;
        font-weight: 700;
        color: #444;
    }
    .token-model-row .token-model-count {
        font-size: 11px;
        font-weight: 700;
        color: #FF528F;
    }
    .token-model-row .token-model-count small {
        color: #AAA;
        font-weight: 600;
    }
    .token-bar-bg {
        background: #F5F5F5;
        height: 7px;
        border-radius: 4px;
        overflow: hidden;
    }
    .token-bar-fill {
        height: 100%;
        border-radius: 4px;
        background: linear-gradient(90deg, #FF528F, #FF7A9F);
        transition: width 0.5s ease;
    }

    .clickable-cell {
        cursor: pointer;
        text-decoration: underline;
        font-family: monospace;
        font-size: 11px;
    }

    /* Toggle Switch */
    .switch-toggle input:checked + .slider-toggle {
        background-color: #FF528F;
    }
    .switch-toggle input:focus + .slider-toggle {
        box-shadow: 0 0 1px #FF528F;
    }
    .switch-toggle input:checked + .slider-toggle:before {
        transform: translateX(20px);
    }
    .slider-toggle:before {
        position: absolute;
        content: "";
        height: 18px;
        width: 18px;
        left: 3px;
        bottom: 3px;
        background-color: white;
        transition: .4s;
        border-radius: 50%;
    }
</style>

<!-- Auto Refresh Panel -->
<div style="display: flex; justify-content: flex-end; align-items: center; gap: 10px; margin-bottom: 20px;">
    <div style="font-size: 13px; font-weight: 700; color: #555; display: inline-flex; align-items: center; gap: 6px;">
        <i class="fa-solid fa-arrows-rotate" id="refresh-icon"></i> Auto Refresh (30s):
    </div>
    <label class="switch-toggle" style="position: relative; display: inline-block; width: 44px; height: 24px;">
        <input type="checkbox" id="auto-refresh-check" style="opacity: 0; width: 0; height: 0;">
        <span class="slider-toggle" style="position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #ccc; transition: .4s; border-radius: 24px;"></span>
    </label>
</div>

<!-- Token Usage Summary -->
<div class="token-summary">
    <div class="token-total-box">
        <div class="token-label"><i class="fa-solid fa-coins"></i> Total Token Terpakai (Estimasi)</div>
        <div class="token-value">
            @if($tokenTotal >= 1000)
                {{ number_format($tokenTotal / 1000, 1, ',', '.') }} <span style="font-size:16px;">rb token</span>
            @else
                {{ number_format($tokenTotal, 0, ',', '.') }} <span style="font-size:16px;">token</span>
            @endif
        </div>
        <div class="token-sub">
            {{ number_format($tokenTotal, 0, ',', '.') }} token &bull; {{ number_format($tokenTotalCalls, 0, ',', '.') }} panggilan API &bull; estimasi &plusmn;4 karakter/token
        </div>
    </div>
    <div class="token-model-list">
        @forelse($tokenPerModel as $tm)
            @php
                $maxTokens = max(1, $tokenPerModel->max('tokens'));
                $barPercent = min(100, ($tm['tokens'] / $maxTokens) * 100);
            @endphp
            <div class="token-model-row">
                <div class="token-model-head">
                    <span class="token-model-name">{{ $tm['model'] }}</span>
                    <span class="token-model-count">
                        {{ number_format($tm['tokens'], 0, ',', '.') }} token
                        <small>({{ number_format($tm['calls'], 0, ',', '.') }} panggilan)</small>
                    </span>
                </div>
                <div class="token-bar-bg">
                    <div class="token-bar-fill" style="width: {{ $barPercent }}%;"></div>
                </div>
            </div>
        @empty
            <div style="text-align:center; color:#999; font-size:13px;">Belum ada penggunaan token terekam.</div>
        @endforelse
    </div>
</div>

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
        <div class="quota-footer" style="margin-top: 8px; border-top: 1px dashed #EEE; padding-top: 8px;">
            <span>Rasio Sukses:</span>
            <span style="font-weight: bold; color: {{ $successRate['gemini'] >= 95 ? '#2ECC71' : ($successRate['gemini'] >= 80 ? '#F38020' : '#D32F2F') }}">{{ $successRate['gemini'] }}%</span>
        </div>
    </div>

    <!-- Cerebras -->
    <div class="quota-card">
        <div class="quota-header">
            <span class="quota-name">Cerebras Llama 3.1</span>
            <span class="provider-pill provider-cerebras">Limit Harian</span>
        </div>
        <div style="font-size:22px; font-weight:800; margin-bottom:10px;">
            {{ $usageToday['cerebras'] }} <span style="font-size:13px; color:#aaa; font-weight:600;">/ {{ $limits['cerebras'] }} Req</span>
        </div>
        @php
            $cerebrasPercent = min(100, ($usageToday['cerebras'] / $limits['cerebras']) * 100);
            $cerebrasColor = $cerebrasPercent > 80 ? '#D32F2F' : ($cerebrasPercent > 50 ? '#F57C00' : '#9B59B6');
        @endphp
        <div class="quota-bar-bg">
            <div class="quota-bar-fill" style="width: {{ $cerebrasPercent }}%; background: {{ $cerebrasColor }};"></div>
        </div>
        <div class="quota-footer">
            <span>Sisa Kuota: {{ number_format($remainingQuota['cerebras']) }}</span>
            <span>Speed: {{ $latencyAvg['cerebras'] }} ms</span>
        </div>
        <div class="quota-footer" style="margin-top: 8px; border-top: 1px dashed #EEE; padding-top: 8px;">
            <span>Rasio Sukses:</span>
            <span style="font-weight: bold; color: {{ $successRate['cerebras'] >= 95 ? '#2ECC71' : ($successRate['cerebras'] >= 80 ? '#F38020' : '#D32F2F') }}">{{ $successRate['cerebras'] }}%</span>
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
        <div class="quota-footer" style="margin-top: 8px; border-top: 1px dashed #EEE; padding-top: 8px;">
            <span>Rasio Sukses:</span>
            <span style="font-weight: bold; color: {{ $successRate['groq'] >= 95 ? '#2ECC71' : ($successRate['groq'] >= 80 ? '#F38020' : '#D32F2F') }}">{{ $successRate['groq'] }}%</span>
        </div>
    </div>

    <!-- Cloudflare -->
    <div class="quota-card">
        <div class="quota-header">
            <span class="quota-name">Cloudflare Llama 3.1</span>
            <span class="provider-pill provider-cloudflare">Limit Harian</span>
        </div>
        <div style="font-size:22px; font-weight:800; margin-bottom:10px;">
            {{ $usageToday['cloudflare'] }} <span style="font-size:13px; color:#aaa; font-weight:600;">/ {{ $limits['cloudflare'] }} Req</span>
        </div>
        @php
            $cloudflarePercent = min(100, ($usageToday['cloudflare'] / $limits['cloudflare']) * 100);
            $cloudflareColor = $cloudflarePercent > 80 ? '#D32F2F' : ($cloudflarePercent > 50 ? '#F57C00' : '#F38020');
        @endphp
        <div class="quota-bar-bg">
            <div class="quota-bar-fill" style="width: {{ $cloudflarePercent }}%; background: {{ $cloudflareColor }};"></div>
        </div>
        <div class="quota-footer">
            <span>Sisa Kuota: {{ number_format($remainingQuota['cloudflare']) }}</span>
            <span>Speed: {{ $latencyAvg['cloudflare'] }} ms</span>
        </div>
        <div class="quota-footer" style="margin-top: 8px; border-top: 1px dashed #EEE; padding-top: 8px;">
            <span>Rasio Sukses:</span>
            <span style="font-weight: bold; color: {{ $successRate['cloudflare'] >= 95 ? '#2ECC71' : ($successRate['cloudflare'] >= 80 ? '#F38020' : '#D32F2F') }}">{{ $successRate['cloudflare'] }}%</span>
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
        <div class="quota-footer" style="margin-top: 8px; border-top: 1px dashed #EEE; padding-top: 8px;">
            <span>Rasio Sukses:</span>
            <span style="font-weight: bold; color: {{ $successRate['nvidia'] >= 95 ? '#2ECC71' : ($successRate['nvidia'] >= 80 ? '#F38020' : '#D32F2F') }}">{{ $successRate['nvidia'] }}%</span>
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

    <!-- Monthly Token usage Bar Chart -->
    <div class="chart-card-lg">
        <div class="card-panel-title"><i class="fa-solid fa-chart-bar" style="color:#FF528F;"></i> Tren Penggunaan Token Bulanan (6 Bulan Terakhir)</div>
        <div style="height:250px;">
            <canvas id="monthlyTokenChart"></canvas>
        </div>
        <script>
            new Chart(document.getElementById('monthlyTokenChart').getContext('2d'), {
                type: 'bar',
                data: {
                    labels: {!! json_encode($monthlyTokensLabels) !!},
                    datasets: [{
                        label: 'Token',
                        data: {!! json_encode($monthlyTokensData) !!},
                        backgroundColor: 'rgba(255, 82, 143, 0.2)',
                        borderColor: '#FF528F',
                        borderWidth: 2,
                        borderRadius: 8,
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false }
                    },
                    scales: {
                        y: { 
                            beginAtZero: true, 
                            grid: { color: '#F0F0F0' },
                            ticks: { 
                                font: { family: 'Outfit' },
                                callback: function(value) {
                                    return value >= 1000 ? (value/1000) + 'k' : value;
                                }
                            }
                        },
                        x: { 
                            grid: { display: false }, 
                            ticks: { font: { family: 'Outfit', size: 10 } } 
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
                    <th>Token</th>
                    <th>Pesan Error</th>
                    <th>Respon AI</th>
                </tr>
            </thead>
            <tbody>
                @foreach($allLogs as $log)
                    <tr>
                        <td>{{ $log->created_at->format('d/m/y H:i:s') }}</td>
                        <td><strong>{{ $log->user ? $log->user->name : 'Guest User' }}</strong></td>
                        <td><span class="badge {{ $log->feature === 'stt' ? 'badge-stt' : ($log->feature === 'ocr' ? 'badge-ocr' : 'badge-advisor') }}">{{ strtoupper($log->feature) }}</span></td>
                        <td><span class="provider-pill provider-{{ strtolower($log->provider) }}">{{ $log->model_name ?? $log->provider }}</span></td>
                        <td><span class="badge {{ $log->status === 'success' ? 'badge-success' : 'badge-danger' }}">{{ $log->status }}</span></td>
                        <td><strong>{{ number_format($log->latency_ms) }} ms</strong></td>
                        <td><strong>{{ $log->characters_processed > 0 ? number_format(ceil($log->characters_processed / 4)) : '-' }}</strong></td>
                        <td>
                            @if($log->error_message)
                                <span class="clickable-cell" style="color:#C62828;"
                                      onclick="showLogDetailModal(this, 'Detail Pesan Error')"
                                      data-content="{{ $log->error_message }}">
                                    {{ Str::limit($log->error_message, 45) }}
                                </span>
                            @else
                                -
                            @endif
                        </td>
                        <td>
                            @if($log->response_content)
                                <span class="clickable-cell" style="color:#1E88E5;"
                                      onclick="showLogDetailModal(this, 'Detail Respon AI')"
                                      data-content="{{ $log->response_content }}">
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
function showLogDetailModal(element, title) {
    const rawContent = element.getAttribute('data-content');
    let formattedContent = rawContent;
    try {
        const parsed = JSON.parse(rawContent);
        formattedContent = JSON.stringify(parsed, null, 4);
    } catch (e) {
        // Not JSON
    }

    Swal.fire({
        title: title,
        html: '<pre style="text-align: left; background: #f4f6f7; padding: 12px; border-radius: 8px; font-size: 11px; overflow-x: auto; max-height: 400px; font-family: monospace; white-space: pre-wrap; word-wrap: break-word;">' +
              escapeHtml(formattedContent) +
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

// Auto-Refresh Logic
document.addEventListener("DOMContentLoaded", function() {
    const refreshCheck = document.getElementById('auto-refresh-check');
    const refreshIcon = document.getElementById('refresh-icon');
    let refreshInterval;

    if (localStorage.getItem('ai_monitor_auto_refresh') === 'true') {
        if (refreshCheck) refreshCheck.checked = true;
        startRefresh();
    }

    if (refreshCheck) {
        refreshCheck.addEventListener('change', function() {
            if (this.checked) {
                localStorage.setItem('ai_monitor_auto_refresh', 'true');
                startRefresh();
            } else {
                localStorage.setItem('ai_monitor_auto_refresh', 'false');
                stopRefresh();
            }
        });
    }

    function startRefresh() {
        if (refreshIcon) {
            refreshIcon.classList.add('fa-spin');
        }
        refreshInterval = setInterval(function() {
            window.location.reload();
        }, 30000); // 30 seconds
    }

    function stopRefresh() {
        if (refreshIcon) {
            refreshIcon.classList.remove('fa-spin');
        }
        clearInterval(refreshInterval);
    }
});
</script>
@endsection
