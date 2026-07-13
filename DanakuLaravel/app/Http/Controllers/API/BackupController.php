<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Backup;
use Illuminate\Http\Request;

class BackupController extends Controller
{
    public function backup(Request $request)
    {
        $request->validate([
            'transaksi' => 'present|array',
            'wallets' => 'present|array',
            'categories' => 'present|array',
        ]);

        $user = $request->user();

        // Idempotency / Double-Submit protection
        $payloadHash = md5(json_encode($request->only(['transaksi', 'wallets', 'categories'])));
        $cacheKey = 'backup_hash_' . $user->id;
        $cachedHash = \Illuminate\Support\Facades\Cache::get($cacheKey);

        if ($cachedHash === $payloadHash) {
            return response()->json([
                'message' => 'Data berhasil dicadangkan ke server (idempotent)!',
                'backup_date' => now()->toIso8601String()
            ], 200);
        }

        // Menyimpan baru atau menimpa cadangan lama milik user ini
        $backup = Backup::updateOrCreate(
            ['user_id' => $user->id],
            ['data' => json_encode($request->all())]
        );

        \Illuminate\Support\Facades\Cache::put($cacheKey, $payloadHash, 10);

        return response()->json([
            'message' => 'Data berhasil dicadangkan ke server!',
            'backup_date' => now()->toIso8601String()
        ], 200);
    }

    public function restore(Request $request)
    {
        $user = $request->user();
        $backup = Backup::where('user_id', $user->id)->first();

        if (!$backup) {
            return response()->json(['message' => 'Tidak ditemukan data cadangan untuk akun ini!'], 404);
        }

        return response()->json([
            'message' => 'Data cadangan ditemukan!',
            'data' => json_decode($backup->data)
        ], 200);
    }
}
