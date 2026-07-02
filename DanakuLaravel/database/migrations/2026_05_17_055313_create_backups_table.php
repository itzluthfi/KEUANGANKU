<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void {
        Schema::create('backups', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->longText('data'); // Menyimpan Payload JSON transaksi, dompet, & kategori
            $table->timestamps();
        });
    }

    public function down(): void {
        Schema::dropIfExists('backups');
    }
};
