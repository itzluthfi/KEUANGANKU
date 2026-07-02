<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AIController extends Controller
{
    // List kategori pengeluaran dan pemasukan
    private $categoriesKeluar = ['Makan', 'Minum', 'Bensin', 'Parkir', 'Kopi', 'Sosial', 'Harian', 'Admin', 'Hadiah', 'Ban', 'Jalan', 'HP'];
    private $categoriesMasuk = ['Gaji', 'Uang Saku', 'Bonus', 'Lainnya'];

    /**
     * Memproses teks input suara menjadi data transaksi terstruktur.
     */
    public function parseText(Request $request)
    {
        $request->validate([
            'text' => 'required|string|max:1000',
        ]);

        $text = $request->text;
        $startTime = microtime(true);

        // Mekanisme Fallback: Gemini -> Groq -> Nvidia
        try {
            $data = $this->callGeminiParseText($text);
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('stt', 'gemini', 'gemini-2.5-flash', 'success', strlen($text) + strlen(json_encode($data)), $latency, null, json_encode($data));
            return response()->json($data);
        } catch (\Exception $e) {
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('stt', 'gemini', 'gemini-2.5-flash', 'failed', strlen($text), $latency, $e->getMessage());
            Log::warning("Gemini parseText failed: " . $e->getMessage());
        }

        $startTime = microtime(true);
        try {
            $data = $this->callGroqParseText($text);
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('stt', 'groq', 'qwen-2.5-32b', 'success', strlen($text) + strlen(json_encode($data)), $latency, null, json_encode($data));
            return response()->json($data);
        } catch (\Exception $e) {
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('stt', 'groq', 'qwen-2.5-32b', 'failed', strlen($text), $latency, $e->getMessage());
            Log::warning("Groq parseText failed: " . $e->getMessage());
        }

        $startTime = microtime(true);
        try {
            $data = $this->callNvidiaParseText($text);
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('stt', 'nvidia', 'llama-3.2-11b', 'success', strlen($text) + strlen(json_encode($data)), $latency, null, json_encode($data));
            return response()->json($data);
        } catch (\Exception $e) {
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('stt', 'nvidia', 'llama-3.2-11b', 'failed', strlen($text), $latency, $e->getMessage());
            Log::error("Nvidia parseText failed: " . $e->getMessage());
            return response()->json([
                'message' => 'Seluruh layanan AI gagal memproses teks.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Memproses gambar struk belanja menjadi data transaksi terstruktur.
     */
    public function parseReceipt(Request $request)
    {
        $request->validate([
            'image' => 'required|image|max:10240', // Maks 10MB
        ]);

        $imageFile = $request->file('image');
        $base64Image = base64_encode(file_get_contents($imageFile->getPathname()));
        $mimeType = $imageFile->getMimeType();
        $startTime = microtime(true);

        // Mekanisme Fallback: Gemini -> Groq -> Nvidia
        try {
            $data = $this->callGeminiParseReceipt($base64Image, $mimeType);
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('ocr', 'gemini', 'gemini-2.5-flash', 'success', 1000 + strlen(json_encode($data)), $latency, null, json_encode($data));
            return response()->json($data);
        } catch (\Exception $e) {
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('ocr', 'gemini', 'gemini-2.5-flash', 'failed', 1000, $latency, $e->getMessage());
            Log::warning("Gemini parseReceipt failed: " . $e->getMessage());
        }

        $startTime = microtime(true);
        try {
            $data = $this->callGroqParseReceipt($base64Image, $mimeType);
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('ocr', 'groq', 'qwen-2.5-32b', 'success', 1000 + strlen(json_encode($data)), $latency, null, json_encode($data));
            return response()->json($data);
        } catch (\Exception $e) {
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('ocr', 'groq', 'qwen-2.5-32b', 'failed', 1000, $latency, $e->getMessage());
            Log::warning("Groq parseReceipt failed: " . $e->getMessage());
        }

        $startTime = microtime(true);
        try {
            $data = $this->callNvidiaParseReceipt($base64Image, $mimeType);
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('ocr', 'nvidia', 'llama-3.2-11b', 'success', 1000 + strlen(json_encode($data)), $latency, null, json_encode($data));
            return response()->json($data);
        } catch (\Exception $e) {
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('ocr', 'nvidia', 'llama-3.2-11b', 'failed', 1000, $latency, $e->getMessage());
            Log::error("Nvidia parseReceipt failed: " . $e->getMessage());
            return response()->json([
                'message' => 'Seluruh layanan AI gagal menganalisis struk belanja.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // =========================================================================
    // 🌐 BAGIAN 1: IMPLEMENTASI GEMINI AI
    // =========================================================================

    private function callGeminiParseText($text)
    {
        $apiKey = env('GEMINI_API_KEY');
        if (empty($apiKey)) throw new \Exception("Gemini API key is empty.");

        $prompt = $this->getTextPrompt($text);

        $response = Http::post("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={$apiKey}", [
            'contents' => [
                'parts' => [
                    ['text' => $prompt]
                ]
            ],
            'generationConfig' => [
                'response_mime_type' => 'application/json'
            ]
        ]);

        if ($response->failed()) {
            throw new \Exception("Gemini API HTTP Error: " . $response->body());
        }

        return $this->cleanResponse($response->json('candidates.0.content.parts.0.text'));
    }

    private function callGeminiParseReceipt($base64Image, $mimeType)
    {
        $apiKey = env('GEMINI_API_KEY');
        if (empty($apiKey)) throw new \Exception("Gemini API key is empty.");

        $prompt = $this->getReceiptPrompt();

        $response = Http::post("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={$apiKey}", [
            'contents' => [
                'parts' => [
                    ['text' => $prompt],
                    [
                        'inlineData' => [
                            'mimeType' => $mimeType,
                            'data' => $base64Image
                        ]
                    ]
                ]
            ],
            'generationConfig' => [
                'response_mime_type' => 'application/json'
            ]
        ]);

        if ($response->failed()) {
            throw new \Exception("Gemini API HTTP Error: " . $response->body());
        }

        return $this->cleanResponse($response->json('candidates.0.content.parts.0.text'));
    }

    // =========================================================================
    // 🌐 BAGIAN 2: IMPLEMENTASI GROQ AI
    // =========================================================================

    private function callGroqParseText($text)
    {
        $apiKey = env('GROQ_API_KEY');
        if (empty($apiKey)) throw new \Exception("Groq API key is empty.");

        $prompt = $this->getTextPrompt($text);

        $response = Http::withHeaders([
            'Authorization' => "Bearer {$apiKey}",
            'Content-Type' => 'application/json',
        ])->post("https://api.groq.com/openai/v1/chat/completions", [
            'model' => 'llama-3.3-70b-versatile',
            'messages' => [
                ['role' => 'user', 'content' => $prompt]
            ],
            'response_format' => ['type' => 'json_object']
        ]);

        if ($response->failed()) {
            throw new \Exception("Groq API HTTP Error: " . $response->body());
        }

        return $this->cleanResponse($response->json('choices.0.message.content'));
    }

    private function callGroqParseReceipt($base64Image, $mimeType)
    {
        $apiKey = env('GROQ_API_KEY');
        if (empty($apiKey)) throw new \Exception("Groq API key is empty.");

        $prompt = $this->getReceiptPrompt();

        $response = Http::withHeaders([
            'Authorization' => "Bearer {$apiKey}",
            'Content-Type' => 'application/json',
        ])->post("https://api.groq.com/openai/v1/chat/completions", [
            'model' => 'qwen/qwen3.6-27b',
            'messages' => [
                [
                    'role' => 'user',
                    'content' => [
                        ['type' => 'text', 'text' => $prompt],
                        [
                            'type' => 'image_url',
                            'image_url' => [
                                'url' => "data:{$mimeType};base64,{$base64Image}"
                            ]
                        ]
                    ]
                ]
            ],
            'response_format' => ['type' => 'json_object']
        ]);

        if ($response->failed()) {
            throw new \Exception("Groq API HTTP Error: " . $response->body());
        }

        return $this->cleanResponse($response->json('choices.0.message.content'));
    }

    // =========================================================================
    // 🌐 BAGIAN 3: IMPLEMENTASI NVIDIA NIM/DEVELOPER AI
    // =========================================================================

    private function callNvidiaParseText($text)
    {
        $apiKey = env('NVIDIA_API_KEY');
        if (empty($apiKey)) throw new \Exception("Nvidia API key is empty.");

        $prompt = $this->getTextPrompt($text);

        $response = Http::withHeaders([
            'Authorization' => "Bearer {$apiKey}",
            'Content-Type' => 'application/json',
        ])->post("https://integrate.api.nvidia.com/v1/chat/completions", [
            'model' => 'meta/llama-3.1-8b-instruct',
            'messages' => [
                ['role' => 'user', 'content' => $prompt]
            ],
            'response_format' => ['type' => 'json_object']
        ]);

        if ($response->failed()) {
            throw new \Exception("Nvidia API HTTP Error: " . $response->body());
        }

        return $this->cleanResponse($response->json('choices.0.message.content'));
    }

    private function callNvidiaParseReceipt($base64Image, $mimeType)
    {
        $apiKey = env('NVIDIA_API_KEY');
        if (empty($apiKey)) throw new \Exception("Nvidia API key is empty.");

        $prompt = $this->getReceiptPrompt();

        $response = Http::withHeaders([
            'Authorization' => "Bearer {$apiKey}",
            'Content-Type' => 'application/json',
        ])->post("https://integrate.api.nvidia.com/v1/chat/completions", [
            'model' => 'meta/llama-3.2-11b-vision-instruct',
            'messages' => [
                [
                    'role' => 'user',
                    'content' => [
                        ['type' => 'text', 'text' => $prompt],
                        [
                            'type' => 'image_url',
                            'image_url' => [
                                'url' => "data:{$mimeType};base64,{$base64Image}"
                            ]
                        ]
                    ]
                ]
            ],
            'response_format' => ['type' => 'json_object']
        ]);

        if ($response->failed()) {
            throw new \Exception("Nvidia API HTTP Error: " . $response->body());
        }

        return $this->cleanResponse($response->json('choices.0.message.content'));
    }

    // =========================================================================
    // ⚙️ FUNGSI HELPER & PROMPT TEMPLATES
    // =========================================================================

    private function getTextPrompt($text)
    {
        $keluarList = implode(', ', $this->categoriesKeluar);
        $masukList = implode(', ', $this->categoriesMasuk);

        return "Analyze this financial spoken text and extract transaction details:
\"{$text}\"
Extract:
1. 'jumlah': The transaction amount as a pure integer (numbers only, e.g. \"15 ribu\" -> 15000, \"satu juta\" -> 1000000).
2. 'keterangan': Description of the transaction (string in Indonesian, e.g., 'makan bakso').
3. 'jenis': Either 'masuk' (if it is income/receiving money) or 'keluar' (if it is expense/spending money).
4. 'kategori': Choose ONE category matching best from this list:
   - For 'keluar': {$keluarList}.
   - For 'masuk': {$masukList}.
If no matching category is found, default to 'Lainnya' for masuk, and 'Harian' for keluar.
5. 'items': If the spoken text mentions multiple separate item purchases (e.g. \"bensin 30 ribu dan sate 20 ribu\"), extract them into an array of objects where each object contains:
   - 'nama': The item description or name (string).
   - 'qty': Quantity purchased (integer, default 1).
   - 'harga': Total price for this item (integer).

Output must be ONLY a valid JSON object matching the schema. Do not output any markdown formatting like ```json.";
    }

    private function getReceiptPrompt()
    {
        $keluarList = implode(', ', $this->categoriesKeluar);

        return "Analyze this receipt image and extract:
1. 'jumlah': Total expense amount as a pure integer (numbers only). Ignore subtotal if it is not the final paid amount.
2. 'keterangan': The merchant or store name (string in Indonesian).
3. 'kategori': Choose ONE category matching best from this list: {$keluarList}. Default to 'Harian' if none match.
4. 'tanggal': Receipt transaction date in 'YYYY-MM-DD' format. If not found, use today's date (" . date('Y-m-d') . ").
5. 'jenis': Always set to 'keluar'.
6. 'items': An array of objects, where each object represents an item on the receipt and contains:
   - 'nama': The item description or name (string).
   - 'qty': Quantity purchased (integer, default 1 if not readable).
   - 'harga': Total price for this item (integer, i.e. qty * unit_price).
   - 'kategori': Choose ONE category from this list matching the item best: {$keluarList}. Default to 'Harian'.

Output must be ONLY a valid JSON object matching the schema. Do not output any markdown formatting like ```json.";
    }

    private function cleanResponse($responseText)
    {
        $clean = trim($responseText);
        
        // Hilangkan pembungkus markdown jika ada
        $clean = preg_replace('/^```json/i', '', $clean);
        $clean = preg_replace('/^```/i', '', $clean);
        $clean = preg_replace('/```$/i', '', $clean);
        $clean = trim($clean);

        $decoded = json_decode($clean, true);

        if (json_last_error() !== JSON_ERROR_NONE) {
            // Coba cari pola JSON { ... } di dalam teks jika LLM mengembalikan teks penjelasan tambahan
            if (preg_match('/\{.*\}/s', $clean, $matches)) {
                $clean = $matches[0];
                $decoded = json_decode($clean, true);
            }
        }

        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new \Exception("LLM returned invalid JSON: " . $responseText);
        }

        // Normalisasi format tanggal (titik atau slash ke tanda hubung)
        $tanggal = isset($decoded['tanggal']) ? (string) $decoded['tanggal'] : date('Y-m-d');
        $tanggalClean = preg_replace('/[\.\/]/', '-', $tanggal);
        
        $timestamp = strtotime($tanggalClean);
        if ($timestamp !== false) {
            $tanggalFormatted = date('Y-m-d', $timestamp);
        } else {
            $parts = explode('-', $tanggalClean);
            if (count($parts) === 3) {
                if (strlen($parts[2]) === 4) {
                    $tanggalFormatted = sprintf('%04d-%02d-%02d', (int)$parts[2], (int)$parts[1], (int)$parts[0]);
                } else if (strlen($parts[0]) === 4) {
                    $tanggalFormatted = sprintf('%04d-%02d-%02d', (int)$parts[0], (int)$parts[1], (int)$parts[2]);
                } else {
                    $tanggalFormatted = date('Y-m-d');
                }
            } else {
                $tanggalFormatted = date('Y-m-d');
            }
        }

        // Normalisasi field yang dikembalikan
        return [
            'jumlah' => isset($decoded['jumlah']) ? (int) $decoded['jumlah'] : 0,
            'keterangan' => isset($decoded['keterangan']) ? (string) $decoded['keterangan'] : '',
            'jenis' => isset($decoded['jenis']) && strtolower($decoded['jenis']) === 'masuk' ? 'masuk' : 'keluar',
            'kategori' => isset($decoded['kategori']) ? (string) $decoded['kategori'] : 'Harian',
            'tanggal' => $tanggalFormatted,
            'items' => isset($decoded['items']) ? (array) $decoded['items'] : [],
        ];
    }

    private function logUsage($feature, $provider, $modelName, $status, $chars, $latencyMs, $errorMessage = null, $responseContent = null)
    {
        try {
            \App\Models\ApiLog::create([
                'user_id' => auth('sanctum')->id(),
                'feature' => $feature,
                'provider' => $provider,
                'model_name' => $modelName,
                'status' => $status,
                'characters_processed' => $chars,
                'latency_ms' => (int) $latencyMs,
                'error_message' => $errorMessage,
                'response_content' => $responseContent,
            ]);
        } catch (\Exception $e) {
            Log::error("Failed to save api log: " . $e->getMessage());
        }
    }
}
