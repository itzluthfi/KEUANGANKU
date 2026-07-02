<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Backup;
use App\Models\ApiLog;
use Illuminate\Support\Facades\Auth;

class AdminController extends Controller
{
    /**
     * Tampilan Landing Page /
     */
    public function index()
    {
        return view('landing');
    }

    /**
     * Tampilan Halaman Login Admin
     */
    public function showLogin()
    {
        if (Auth::check() && Auth::user()->role === 'admin') {
            return redirect()->route('admin.dashboard');
        }
        return view('login');
    }

    /**
     * Proses Login Admin
     */
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

    /**
     * Portal Dashboard Admin
     */
    public function dashboard()
    {
        // 📊 1. Statistik Utama
        $totalUsers = User::where('role', '!=', 'admin')->count();
        $totalBackups = Backup::count();
        
        // Hitung total transaksi dari payload JSON backup
        $totalTransactions = 0;
        $backups = Backup::all();
        foreach ($backups as $b) {
            $payload = json_decode($b->data, true);
            if (isset($payload['transaksi'])) {
                $totalTransactions += count($payload['transaksi']);
            }
        }

        $totalApiRequests = ApiLog::count();
        $apiRequestsToday = ApiLog::whereDate('created_at', today())->count();

        // 📈 2. Statistik Penggunaan Token AI per Provider (Gemini vs Groq vs Nvidia)
        $providers = ApiLog::selectRaw('provider, sum(characters_processed) as total_chars, count(*) as count')
            ->groupBy('provider')
            ->get();
            
        $providerLabels = [];
        $providerChars = [];
        $providerColors = [];
        
        foreach ($providers as $p) {
            $providerLabels[] = ucfirst($p->provider);
            $providerChars[] = (int) $p->total_chars;
            
            // Warna disesuaikan dengan tema
            if (strtolower($p->provider) === 'gemini') $providerColors[] = '#E24C80';
            elseif (strtolower($p->provider) === 'groq') $providerColors[] = '#4A90E2';
            else $providerColors[] = '#2ECC71';
        }

        // 📝 3. Aktivitas Log AI Terbaru
        $recentLogs = ApiLog::with('user')
            ->latest()
            ->limit(10)
            ->get();

        // 💾 4. List Backup Pengguna
        $usersList = User::where('role', '!=', 'admin')
            ->with('backup')
            ->get()
            ->map(function ($u) {
                $backupSize = 0;
                $transactionCount = 0;
                if ($u->backup) {
                    $backupSize = strlen($u->backup->data);
                    $payload = json_decode($u->backup->data, true);
                    if (isset($payload['transaksi'])) {
                        $transactionCount = count($payload['transaksi']);
                    }
                }
                return [
                    'name' => $u->name,
                    'email' => $u->email,
                    'last_sync' => $u->backup ? $u->backup->updated_at->diffForHumans() : 'Belum pernah',
                    'backup_size' => number_format($backupSize / 1024, 2) . ' KB',
                    'transactions' => $transactionCount,
                ];
            });

        return view('admin.dashboard', compact(
            'totalUsers',
            'totalBackups',
            'totalTransactions',
            'totalApiRequests',
            'apiRequestsToday',
            'providerLabels',
            'providerChars',
            'providerColors',
            'recentLogs',
            'usersList'
        ));
    }

    /**
     * Proses Keluar (Logout)
     */
    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect()->route('login');
    }
}
