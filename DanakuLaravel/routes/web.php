<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminController;

// 1. Landing Page
Route::get('/', [AdminController::class, 'index'])->name('landing');

// 2. Authentication Admin
Route::get('/login', [AdminController::class, 'showLogin'])->name('login');
Route::post('/login', [AdminController::class, 'login']);
Route::post('/logout', [AdminController::class, 'logout'])->name('logout');

// 3. Protected Admin Pages
Route::middleware(['auth', 'admin'])->prefix('admin')->group(function () {
    Route::get('/dashboard', [AdminController::class, 'dashboard'])->name('admin.dashboard');
    Route::get('/ai-monitoring', [AdminController::class, 'aiMonitoring'])->name('admin.ai-monitoring');
    Route::get('/users', [AdminController::class, 'users'])->name('admin.users');
    Route::get('/users/{id}/transactions', [AdminController::class, 'userTransactions'])->name('admin.users.transactions');
    Route::delete('/users/{id}', [AdminController::class, 'deleteUser'])->name('admin.users.delete');
});
