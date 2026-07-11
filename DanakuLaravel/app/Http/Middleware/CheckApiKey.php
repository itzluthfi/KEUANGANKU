<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class CheckApiKey
{
    public function handle(Request $request, Closure $next)
    {
        $apiKey = $request->header('X-Danaku-API-Key');
        if ($apiKey !== env('DANAKU_API_KEY', 'secure_danaku_key_2026')) {
            return response()->json(['message' => 'Unauthorized API Key'], 401);
        }
        return $next($request);
    }
}
