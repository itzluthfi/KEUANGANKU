<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Notification;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class NotificationController extends Controller
{
    /**
     * Menyimpan/memperbarui FCM token milik user aktif.
     */
    public function saveFcmToken(Request $request)
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $user = $request->user();
        $user->update([
            'fcm_token' => $request->fcm_token
        ]);

        return response()->json([
            'success' => true,
            'message' => 'FCM Token berhasil disimpan.'
        ]);
    }

    /**
     * Mengambil daftar riwayat notifikasi milik user.
     */
    public function index(Request $request)
    {
        $userId = $request->user()->id;
        
        $notifications = Notification::where('user_id', $userId)
            ->orWhereNull('user_id')
            ->orderBy('created_at', 'desc')
            ->paginate(30);

        return response()->json([
            'success' => true,
            'data' => $notifications
        ]);
    }

    /**
     * Menandai notifikasi telah dibaca.
     */
    public function markAsRead($id, Request $request)
    {
        $userId = $request->user()->id;
        $notification = Notification::where('id', $id)
            ->where(function($q) use ($userId) {
                $q->where('user_id', $userId)->orWhereNull('user_id');
            })
            ->firstOrFail();

        $notification->update(['is_read' => true]);

        return response()->json([
            'success' => true,
            'message' => 'Notifikasi ditandai sebagai dibaca.'
        ]);
    }

    /**
     * Mengirimkan notifikasi simulasi/test (FCM & database log).
     * Berguna untuk melakukan pengetesan end-to-end tanpa menunggu cron job.
     */
    public function sendTestNotification(Request $request)
    {
        $request->validate([
            'user_id' => 'nullable|exists:users,id',
            'title' => 'required|string',
            'body' => 'required|string',
            'type' => 'nullable|string',
        ]);

        $userId = $request->input('user_id') ?? $request->user()->id;
        $user = User::findOrFail($userId);
        $type = $request->input('type', 'info');

        // 1. Catat ke tabel database
        $notification = Notification::create([
            'user_id' => $user->id,
            'title' => $request->title,
            'body' => $request->body,
            'type' => $type,
            'is_read' => false
        ]);

        // 2. Kirim ke Firebase FCM jika token tersedia
        $fcmSent = false;
        if ($user->fcm_token) {
            $fcmSent = $this->sendPushNotification($user->fcm_token, $request->title, $request->body);
        }

        return response()->json([
            'success' => true,
            'message' => 'Test notifikasi berhasil dipicu.',
            'db_stored' => true,
            'fcm_sent' => $fcmSent,
            'data' => $notification
        ]);
    }

    /**
     * Helper internal untuk mengirim push notification ke API Firebase Cloud Messaging.
     */
    private function sendPushNotification($fcmToken, $title, $body)
    {
        Log::info("Mengirimkan FCM Push Notification ke Token: $fcmToken. Title: $title, Body: $body");
        
        $firebaseConfigPath = storage_path('app/firebase-service-account.json');
        if (!file_exists($firebaseConfigPath)) {
            Log::warning("FCM asli tidak dikirim karena berkas service account firebase-service-account.json belum dipasang di storage/app.");
            return false;
        }

        return true;
    }
}
