<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ReceiptController extends Controller
{
    /**
     * Simpan foto struk yang diunggah aplikasi mobile.
     * File disimpan di storage/app/public/receipts dan URL publiknya
     * dikembalikan agar disimpan di data transaksi (ikut ter-backup).
     */
    public function store(Request $request)
    {
        $request->validate([
            'image' => 'required|image|mimes:jpeg,jpg,png,webp|max:5120',
        ]);

        $file = $request->file('image');
        $filename = 'struk_' . now()->format('Ymd_His') . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
        $path = $file->storeAs('receipts', $filename, 'public');

        return response()->json([
            'message' => 'Foto struk berhasil disimpan.',
            'url' => asset('storage/' . $path),
        ], 201);
    }
}
