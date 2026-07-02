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
            'transaksi' => 'required|array',
            'wallets' => 'required|array',
            'categories' => 'required|array',
        ]);

        $user = $request->user();

        // Menyimpan baru atau menimpa cadangan lama milik user ini
        $backup = Backup::updateOrCreate(
            ['user_id' => $user->id],
            ['data' => json_encode($request->all())]
        );

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
