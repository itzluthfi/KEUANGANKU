<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ApiLog extends Model
{
    protected $fillable = [
        'user_id',
        'feature',
        'provider',
        'model_name',
        'status',
        'characters_processed',
        'latency_ms',
        'error_message',
        'response_content',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
