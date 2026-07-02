<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('api_logs', function (Blueprint $table) {
            $table->string('model_name')->nullable()->after('provider');
            $table->string('status')->default('success')->after('feature'); // 'success', 'failed'
            $table->integer('latency_ms')->default(0)->after('characters_processed');
            $table->text('error_message')->nullable()->after('latency_ms');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('api_logs', function (Blueprint $table) {
            $table->dropColumn(['model_name', 'status', 'latency_ms', 'error_message']);
        });
    }
};
