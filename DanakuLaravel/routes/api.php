<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\BackupController;
use App\Http\Controllers\API\AIController;
use App\Http\Controllers\API\NotificationController;
use App\Http\Controllers\API\ReceiptController;

// Rute Publik (Bisa diakses tanpa login)
Route::get('/', function () {
    return response()->json([
        'status' => 'online',
        'message' => 'API Awan DanakuApp aktif dan siap melayani!'
    ]);
});

use App\Http\Middleware\CheckApiKey;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware([CheckApiKey::class, 'throttle:20,1'])->group(function () {
    Route::post('/ai/parse-text', [AIController::class, 'parseText']);
    Route::post('/ai/parse-receipt', [AIController::class, 'parseReceipt']);
    Route::post('/receipts', [ReceiptController::class, 'store']);
});

// Rute Privat (Wajib menyertakan Bearer Token Sanctum di Header HTTP)
Route::middleware('auth:sanctum')->group(function () {
    Route::delete('/user/delete-account', [AuthController::class, 'deleteAccount']);
    Route::post('/backup', [BackupController::class, 'backup']);
    Route::get('/restore', [BackupController::class, 'restore']);
    Route::get('/ai/metrics', [AIController::class, 'metrics']);
    Route::post('/ai/advise', [AIController::class, 'advise']);
    
    // Notifikasi & FCM
    Route::post('/save-fcm-token', [NotificationController::class, 'saveFcmToken']);
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::post('/notifications/test', [NotificationController::class, 'sendTestNotification']);
});
