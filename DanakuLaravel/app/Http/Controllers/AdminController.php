<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Backup;
use App\Models\ApiLog;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class AdminController extends Controller
{
    public function index()
    {
        return view('landing');
    }

    public function showLogin()
    {
        if (Auth::check() && Auth::user()->role === 'admin') {
            return redirect()->route('admin.dashboard');
        }
        return view('login');
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        if (Auth::attempt($credentials)) {
            $user = Auth::user();
            if ($user->role === 'admin') {
                $request->session()->regenerate();
                return redirect()->route('admin.dashboard');
            }
            
            Auth::logout();
            return back()->withErrors(['email' => 'Akses ditolak. Akun Anda bukan administrator.']);
        }

        return back()->withErrors(['email' => 'Kredensial yang diberikan tidak cocok dengan data kami.']);
    }

    public function dashboard()
    {
        $totalUsers = User::where('role', '!=', 'admin')->count();
        $totalBackups = Backup::count();
        
        // 1. Hitung total transaksi global dan kategori terpopuler
        $totalTransactions = 0;
        $totalIncome = 0;
        $totalExpense = 0;
        $categoryCounts = [];
        $walletCounts = [];
        
        $backups = Backup::all();
        foreach ($backups as $b) {
            $payload = json_decode($b->data, true);
            if (isset($payload['transaksi'])) {
                $totalTransactions += count($payload['transaksi']);
                foreach ($payload['transaksi'] as $t) {
                    $jumlah = (int) ($t['jumlah'] ?? 0);
                    $jenis = strtolower($t['jenis'] ?? 'keluar');
                    
                    if ($jenis === 'masuk' || $jenis === 'pemasukan') {
                        $totalIncome += $jumlah;
                    } else {
                        $totalExpense += $jumlah;
                    }

                    $cat = $t['kategori'] ?? 'Lain-lain';
                    $categoryCounts[$cat] = ($categoryCounts[$cat] ?? 0) + 1;
                    
                    $w = $t['walletNama'] ?? 'Utama';
                    $walletCounts[$w] = ($walletCounts[$w] ?? 0) + 1;
                }
            }
        }
        $totalVolume = $totalIncome + $totalExpense;

        // Urutkan kategori terpopuler
        arsort($categoryCounts);
        $topCategories = array_slice($categoryCounts, 0, 5);
        $categoryLabels = array_keys($topCategories);
        $categoryValues = array_values($topCategories);

        // Urutkan dompet terpopuler
        arsort($walletCounts);
        $topWallets = array_slice($walletCounts, 0, 5);
        $walletLabels = array_keys($topWallets);
        $walletValues = array_values($topWallets);

        $totalApiRequests = ApiLog::count();
        $apiRequestsToday = ApiLog::whereDate('created_at', today())->count();

        // Riwayat sinkronisasi cadangan awan terbaru
        $recentSyncs = Backup::with('user')
            ->orderBy('updated_at', 'desc')
            ->limit(5)
            ->get();

        return view('admin.dashboard', compact(
            'totalUsers',
            'totalBackups',
            'totalTransactions',
            'totalIncome',
            'totalExpense',
            'totalVolume',
            'totalApiRequests',
            'apiRequestsToday',
            'categoryLabels',
            'categoryValues',
            'walletLabels',
            'walletValues',
            'recentSyncs'
        ));
    }

    public function aiMonitoring()
    {
        // 📊 1. Statistik Kuota Harian (Batas Kuota)
        // Gemini: 1500 request/hari, Cerebras: 14400/hari, Groq: 14400/hari, Cloudflare: 10000/hari, Nvidia: 1000/hari
        $limits = [
            'gemini' => 1500,
            'cerebras' => 14400,
            'groq' => 14400,
            'cloudflare' => 10000,
            'nvidia' => 1000
        ];

        $todayLogs = ApiLog::whereDate('created_at', today())->get();

        $usageToday = [
            'gemini' => $todayLogs->where('provider', 'gemini')->count(),
            'cerebras' => $todayLogs->where('provider', 'cerebras')->count(),
            'groq' => $todayLogs->where('provider', 'groq')->count(),
            'cloudflare' => $todayLogs->where('provider', 'cloudflare')->count(),
            'nvidia' => $todayLogs->where('provider', 'nvidia')->count()
        ];

        $remainingQuota = [
            'gemini' => max(0, $limits['gemini'] - $usageToday['gemini']),
            'cerebras' => max(0, $limits['cerebras'] - $usageToday['cerebras']),
            'groq' => max(0, $limits['groq'] - $usageToday['groq']),
            'cloudflare' => max(0, $limits['cloudflare'] - $usageToday['cloudflare']),
            'nvidia' => max(0, $limits['nvidia'] - $usageToday['nvidia'])
        ];

        // 📈 2. Latency rata-rata per provider (ms)
        $latencyAvg = [
            'gemini' => (int) ApiLog::where('provider', 'gemini')->where('status', 'success')->avg('latency_ms'),
            'cerebras' => (int) ApiLog::where('provider', 'cerebras')->where('status', 'success')->avg('latency_ms'),
            'groq' => (int) ApiLog::where('provider', 'groq')->where('status', 'success')->avg('latency_ms'),
            'cloudflare' => (int) ApiLog::where('provider', 'cloudflare')->where('status', 'success')->avg('latency_ms'),
            'nvidia' => (int) ApiLog::where('provider', 'nvidia')->where('status', 'success')->avg('latency_ms')
        ];

        // 🎯 3. Success Rate per provider (%)
        $successRate = [];
        foreach (['gemini', 'cerebras', 'groq', 'cloudflare', 'nvidia'] as $prov) {
            $total = ApiLog::where('provider', $prov)->count();
            if ($total > 0) {
                $success = ApiLog::where('provider', $prov)->where('status', 'success')->count();
                $successRate[$prov] = round(($success / $total) * 100, 1);
            } else {
                $successRate[$prov] = 100.0;
            }
        }

        // ⏱️ 4. Latency Line Chart (10 request terakhir yang sukses)
        $latestLogsForChart = ApiLog::where('status', 'success')
            ->latest()
            ->limit(15)
            ->get()
            ->reverse();

        $chartLabels = [];
        $chartLatencies = [];
        foreach ($latestLogsForChart as $index => $log) {
            $chartLabels[] = $log->created_at->format('H:i:s');
            $chartLatencies[] = $log->latency_ms;
        }

        // 📝 5. Semua Log AI
        $allLogs = ApiLog::with('user')
            ->latest()
            ->paginate(15);

        // 🔢 6. Estimasi Total Token Terpakai (keseluruhan & per model)
        // Tabel hanya menyimpan characters_processed, jadi token dihitung
        // dengan konversi standar ±4 karakter per token.
        $totalChars = (int) ApiLog::sum('characters_processed');
        $tokenTotal = (int) ceil($totalChars / 4);
        $tokenTotalCalls = ApiLog::count();

        $tokenPerModel = ApiLog::selectRaw("COALESCE(model_name, provider) as model")
            ->selectRaw('SUM(characters_processed) as total_chars')
            ->selectRaw('COUNT(*) as total_calls')
            ->groupBy('model')
            ->orderByDesc('total_chars')
            ->get()
            ->map(fn ($row) => [
                'model' => $row->model,
                'tokens' => (int) ceil($row->total_chars / 4),
                'calls' => (int) $row->total_calls,
            ]);

        return view('admin.ai_monitoring', compact(
            'limits',
            'usageToday',
            'remainingQuota',
            'latencyAvg',
            'successRate',
            'chartLabels',
            'chartLatencies',
            'allLogs',
            'tokenTotal',
            'tokenTotalCalls',
            'tokenPerModel'
        ));
    }

    public function users(Request $request)
    {
        $search = $request->query('search');

        $query = User::where('role', '!=', 'admin');

        if (!empty($search)) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $users = $query->with('backup')
            ->paginate(10)
            ->withQueryString(); // Keep search query parameter in pagination links

        $usersList = [];
        foreach ($users as $u) {
            $backupSize = 0;
            $transactionCount = 0;
            if ($u->backup) {
                $backupSize = strlen($u->backup->data);
                $payload = json_decode($u->backup->data, true);
                if (isset($payload['transaksi'])) {
                    $transactionCount = count($payload['transaksi']);
                }
            }

            // Hitung total token terpakai oleh user ini
            $totalChars = ApiLog::where('user_id', $u->id)->sum('characters_processed');
            $userTokens = (int) ceil($totalChars / 4);

            $usersList[] = [
                'id' => $u->id,
                'name' => $u->name,
                'email' => $u->email,
                'created_at' => $u->created_at->format('d M Y'),
                'last_sync' => $u->backup ? $u->backup->updated_at->diffForHumans() : 'Belum pernah',
                'backup_size' => number_format($backupSize / 1024, 2) . ' KB',
                'transactions' => $transactionCount,
                'tokens' => $userTokens,
            ];
        }

        return view('admin.users', compact('users', 'usersList', 'search'));
    }

    public function userTransactions($id)
    {
        $user = User::findOrFail($id);
        $backup = Backup::where('user_id', $id)->first();
        
        $transactions = [];
        $totalIncome = 0;
        $totalExpense = 0;
        $categoryData = [];

        if ($backup) {
            $payload = json_decode($backup->data, true);
            if (isset($payload['transaksi'])) {
                $transactions = $payload['transaksi'];
                
                // Urutkan berdasarkan tanggal terbaru
                usort($transactions, function ($a, $b) {
                    return strcmp($b['tanggal'] ?? '', $a['tanggal'] ?? '');
                });

                foreach ($transactions as $t) {
                    $jumlah = (int) ($t['jumlah'] ?? 0);
                    $jenis = strtolower($t['jenis'] ?? 'keluar');
                    $kategori = $t['kategori'] ?? 'Lain-lain';

                    if ($jenis === 'masuk') {
                        $totalIncome += $jumlah;
                    } else {
                        $totalExpense += $jumlah;
                        $categoryData[$kategori] = ($categoryData[$kategori] ?? 0) + $jumlah;
                    }
                }
            }
        }

        arsort($categoryData);
        $categoryLabels = array_keys($categoryData);
        $categoryValues = array_values($categoryData);

        return view('admin.user_transactions', compact(
            'user',
            'transactions',
            'totalIncome',
            'totalExpense',
            'categoryLabels',
            'categoryValues'
        ));
    }

    public function deleteUser($id)
    {
        $user = User::findOrFail($id);
        if ($user->role === 'admin') {
            return back()->with('error', 'Akun administrator tidak bisa dihapus!');
        }

        $user->delete();
        return redirect()->route('admin.users')->with('success', 'Akun pengguna berhasil dihapus dari sistem.');
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect()->route('login');
    }
}
