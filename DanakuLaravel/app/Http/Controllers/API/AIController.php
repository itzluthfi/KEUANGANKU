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

        // Fallback: Gemini -> Cerebras -> Groq -> Cloudflare -> Nvidia
        
        // 1. Gemini
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

        // 2. Cerebras
        $startTime = microtime(true);
        try {
            $data = $this->callCerebrasParseText($text);
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('stt', 'cerebras', 'gemma-4-31b', 'success', strlen($text) + strlen(json_encode($data)), $latency, null, json_encode($data));
            return response()->json($data);
        } catch (\Exception $e) {
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('stt', 'cerebras', 'gemma-4-31b', 'failed', strlen($text), $latency, $e->getMessage());
            Log::warning("Cerebras parseText failed: " . $e->getMessage());
        }

        // 3. Groq
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

        // 4. Cloudflare
        $startTime = microtime(true);
        try {
            $data = $this->callCloudflareParseText($text);
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('stt', 'cloudflare', 'llama-3.1-8b-instruct-fp8', 'success', strlen($text) + strlen(json_encode($data)), $latency, null, json_encode($data));
            return response()->json($data);
        } catch (\Exception $e) {
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('stt', 'cloudflare', 'llama-3.1-8b-instruct-fp8', 'failed', strlen($text), $latency, $e->getMessage());
            Log::warning("Cloudflare parseText failed: " . $e->getMessage());
        }

        // 5. Nvidia
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

        // Fallback: Gemini -> Cloudflare -> Groq -> Nvidia

        // 1. Gemini
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

        // 2. Cloudflare (Vision Model)
        $startTime = microtime(true);
        try {
            $data = $this->callCloudflareParseReceipt($base64Image, $mimeType);
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('ocr', 'cloudflare', 'llama-3.2-11b-vision-instruct', 'success', 1000 + strlen(json_encode($data)), $latency, null, json_encode($data));
            return response()->json($data);
        } catch (\Exception $e) {
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('ocr', 'cloudflare', 'llama-3.2-11b-vision-instruct', 'failed', 1000, $latency, $e->getMessage());
            Log::warning("Cloudflare parseReceipt failed: " . $e->getMessage());
        }

        // 3. Groq
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

        // 4. Nvidia
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
    // 🌐 BAGIAN 4: IMPLEMENTASI CEREBRAS AI
    // =========================================================================

    private function callCerebrasParseText($text)
    {
        $apiKey = env('CEREBRAS_API_KEY');
        if (empty($apiKey)) throw new \Exception("Cerebras API key is empty.");

        $prompt = $this->getTextPrompt($text);

        $response = Http::withHeaders([
            'Authorization' => "Bearer {$apiKey}",
            'Content-Type' => 'application/json',
        ])->post("https://api.cerebras.ai/v1/chat/completions", [
            'model' => 'gemma-4-31b',
            'messages' => [
                ['role' => 'user', 'content' => $prompt]
            ],
            'response_format' => ['type' => 'json_object']
        ]);

        if ($response->failed()) {
            throw new \Exception("Cerebras API HTTP Error: " . $response->body());
        }

        return $this->cleanResponse($response->json('choices.0.message.content'));
    }

    // =========================================================================
    // 🌐 BAGIAN 5: IMPLEMENTASI CLOUDFLARE WORKERS AI
    // =========================================================================

    private function callCloudflareParseText($text)
    {
        $accountId = env('CLOUDFLARE_ACCOUNT_ID');
        $apiToken = env('CLOUDFLARE_API_TOKEN');
        if (empty($accountId) || empty($apiToken)) {
            throw new \Exception("Cloudflare Account ID or API Token is empty.");
        }

        $prompt = $this->getTextPrompt($text);

        $response = Http::withHeaders([
            'Authorization' => "Bearer {$apiToken}",
            'Content-Type' => 'application/json',
        ])->post("https://api.cloudflare.com/client/v4/accounts/{$accountId}/ai/run/@cf/meta/llama-3.1-8b-instruct-fp8", [
            'messages' => [
                ['role' => 'user', 'content' => $prompt]
            ]
        ]);

        if ($response->failed()) {
            throw new \Exception("Cloudflare API HTTP Error: " . $response->body());
        }

        $responseText = $response->json('result.response');
        if (empty($responseText)) {
            throw new \Exception("Cloudflare Workers AI returned empty result: " . $response->body());
        }

        return $this->cleanResponse($responseText);
    }

    private function callCloudflareParseReceipt($base64Image, $mimeType)
    {
        $accountId = env('CLOUDFLARE_ACCOUNT_ID');
        $apiToken = env('CLOUDFLARE_API_TOKEN');
        if (empty($accountId) || empty($apiToken)) {
            throw new \Exception("Cloudflare Account ID or API Token is empty.");
        }

        $prompt = $this->getReceiptPrompt();
        $rawImageBytes = base64_decode($base64Image);
        $imageBytes = array_values(unpack('C*', $rawImageBytes));

        $response = Http::withHeaders([
            'Authorization' => "Bearer {$apiToken}",
            'Content-Type' => 'application/json',
        ])->post("https://api.cloudflare.com/client/v4/accounts/{$accountId}/ai/run/@cf/meta/llama-3.2-11b-vision-instruct", [
            'prompt' => $prompt,
            'image' => $imageBytes
        ]);

        if ($response->failed()) {
            throw new \Exception("Cloudflare API HTTP Error: " . $response->body());
        }

        $responseText = $response->json('result.response');
        if (empty($responseText)) {
            throw new \Exception("Cloudflare Workers AI Vision returned empty result: " . $response->body());
        }

        return $this->cleanResponse($responseText);
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
3. 'jenis': 'masuk' (income/receiving money), 'keluar' (expense/spending money), or 'transfer' (moving money between the user's OWN wallets/accounts, e.g. \"transfer 50 ribu dari dompet utama ke dana\", \"pindahin 100 ribu dari BCA ke gopay\").
4. 'kategori': Choose ONE category matching best from this list:
   - For 'keluar': {$keluarList}.
   - For 'masuk': {$masukList}.
If no matching category is found, default to 'Lainnya' for masuk, and 'Harian' for keluar.
5. 'items': If the spoken text mentions multiple separate transactions or item purchases (e.g. \"bensin 30 ribu dan sate 20 ribu\" or \"beli bensin dan sate total 50 ribu\"), extract them into an array of objects where each object contains:
   - 'nama': The item description or name (string).
   - 'qty': Quantity purchased (integer, default 1).
   - 'harga': Total amount for this item (integer).
   - 'jenis': 'masuk' if this specific item is income/receiving money, 'keluar' if it is spending. Items MAY have different 'jenis' from each other (e.g. \"beli bensin 20 ribu dan dapat uang gojek 30 ribu\" -> bensin is 'keluar' 20000, uang gojek is 'masuk' 30000).
   - 'kategori': Choose ONE category matching this item best, using the 'keluar' list for expense items and the 'masuk' list for income items.
   * PRICE HANDLING RULE: If the user mentions multiple items but does not specify individual prices (e.g., \"beli bensin dan sate seharga 30 ribu\"), split the total 'jumlah' equally among the items (e.g., bensin 15000, sate 15000). If no prices are mentioned at all, set 'harga' to 0 for each item. The sum of 'harga' of all items must equal 'jumlah'.
   * MIXED RULE: When items contain BOTH 'masuk' and 'keluar', still extract every item with its own 'jenis'. Set the top-level 'jenis' to the 'jenis' of the item with the largest amount, and the top-level 'jumlah' to the sum of ALL item 'harga' regardless of their 'jenis'.
6. 'dompet_asal' and 'dompet_tujuan': ONLY when 'jenis' is 'transfer' — the source and destination wallet/account names mentioned by the user (strings, e.g. 'Utama', 'Dana', 'BCA'). Set both to null when not a transfer. For transfers: set 'kategori' to 'Transfer', 'items' to an empty array, and 'keterangan' to a short description like 'Transfer ke Dana'.

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
5. 'jenis': 'keluar' for purchase receipts. Use 'transfer' ONLY if the image is clearly a proof of fund transfer between accounts (bukti transfer bank, mobile banking, or e-wallet screenshot) instead of a purchase receipt.
6. 'items': An array of objects, where each object represents an item on the receipt and contains:
   - 'nama': The item description or name (string).
   - 'qty': Quantity purchased (integer, default 1 if not readable).
   - 'harga': Total adjusted price for this item (integer, i.e. (qty * unit_price) adjusted to include its proportional share of any taxes, service charges, and discounts). Always positive. Do NOT include taxes, discounts, or service charges as separate items in this array; instead, distribute them proportionally across the actual items so that the sum of all items' 'harga' values matches the final 'jumlah' perfectly.
   - 'kategori': Choose ONE category from this list matching the item best: {$keluarList}. Default to 'Harian'.
   - 'jenis': 'keluar' by default. Use 'masuk' ONLY for lines that clearly represent money received by the customer, such as refund, cashback, reimbursement, or deposit returned.
7. 'dompet_asal' and 'dompet_tujuan': ONLY when 'jenis' is 'transfer' — the sender and recipient account/bank/e-wallet names if readable (strings), otherwise null. For transfer proofs: set 'keterangan' like 'Transfer ke <recipient name>', 'kategori' to 'Transfer', and 'items' to an empty array.

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
        $jenisRaw = isset($decoded['jenis']) ? strtolower((string) $decoded['jenis']) : 'keluar';
        $jenis = in_array($jenisRaw, ['masuk', 'transfer'], true) ? $jenisRaw : 'keluar';

        return [
            'jumlah' => isset($decoded['jumlah']) ? (int) $decoded['jumlah'] : 0,
            'keterangan' => isset($decoded['keterangan']) ? (string) $decoded['keterangan'] : '',
            'jenis' => $jenis,
            'kategori' => isset($decoded['kategori']) ? (string) $decoded['kategori'] : 'Harian',
            'tanggal' => $tanggalFormatted,
            'items' => isset($decoded['items']) ? (array) $decoded['items'] : [],
            'dompet_asal' => isset($decoded['dompet_asal']) && $decoded['dompet_asal'] !== '' ? (string) $decoded['dompet_asal'] : null,
            'dompet_tujuan' => isset($decoded['dompet_tujuan']) && $decoded['dompet_tujuan'] !== '' ? (string) $decoded['dompet_tujuan'] : null,
        ];
    }

    public function metrics(Request $request)
    {
        $total = \App\Models\ApiLog::count();
        
        $features = \App\Models\ApiLog::select('feature', \DB::raw('count(*) as count'))
            ->groupBy('feature')
            ->get()
            ->pluck('count', 'feature');
            
        $providers = \App\Models\ApiLog::select('provider')
            ->selectRaw('count(*) as total')
            ->selectRaw('sum(case when status = "success" then 1 else 0 end) as success')
            ->selectRaw('sum(case when status = "failed" then 1 else 0 end) as failed')
            ->selectRaw('avg(latency_ms) as avg_latency')
            ->groupBy('provider')
            ->get()
            ->keyBy('provider')
            ->map(function($row) {
                return [
                    'total' => (int) $row->total,
                    'success' => (int) $row->success,
                    'failed' => (int) $row->failed,
                    'success_rate' => $row->total > 0 ? round(($row->success / $row->total) * 100, 2) . '%' : '0%',
                    'avg_latency_ms' => round($row->avg_latency, 2),
                ];
            });

        $recentErrors = \App\Models\ApiLog::where('status', 'failed')
            ->orderBy('created_at', 'desc')
            ->limit(10)
            ->get(['provider', 'model_name', 'error_message', 'created_at']);

        return response()->json([
            'total_requests' => $total,
            'by_feature' => $features,
            'by_provider' => $providers,
            'recent_errors' => $recentErrors
        ]);
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

    public function advise(Request $request)
    {
        $request->validate([
            'total_pemasukan' => 'required|numeric',
            'total_pengeluaran' => 'required|numeric',
            'kategori_breakdown' => 'required|array',
        ]);

        $in = number_format($request->total_pemasukan, 0, ',', '.');
        $out = number_format($request->total_pengeluaran, 0, ',', '.');
        $net = number_format($request->total_pemasukan - $request->total_pengeluaran, 0, ',', '.');

        $breakdownStr = "";
        foreach ($request->kategori_breakdown as $cat => $val) {
            $breakdownStr .= "- $cat: Rp " . number_format($val, 0, ',', '.') . "\n";
        }

        $prompt = "Anda adalah \"Danaku AI Advisor\", asisten perencana keuangan pribadi yang bijak, cerdas, dan ramah.\n"
            . "Analisis data keuangan pengguna berikut untuk bulan ini:\n"
            . "- Total Pemasukan: Rp $in\n"
            . "- Total Pengeluaran: Rp $out\n"
            . "- Tabungan Bersih (Selisih): Rp $net\n"
            . "- Rincian Pengeluaran per Kategori:\n$breakdownStr\n\n"
            . "Berikan ulasan dan saran keuangan dalam format Markdown terstruktur yang berisi:\n"
            . "1. Ringkasan singkat kesehatan keuangan bulan ini.\n"
            . "2. Analisis Kategori Pengeluaran (kategori mana yang terlalu boros atau perlu diwaspadai).\n"
            . "3. 3 Saran Praktis dan konkret untuk menghemat atau berinvestasi bulan depan.\n"
            . "Gunakan nada bicara yang menyemangati, bersahabat, ramah, dan profesional. Jangan gunakan bahasa yang terlalu kaku.";

        $startTime = microtime(true);

        // Fallback pipeline: Gemini -> Cerebras -> Groq -> Cloudflare -> Nvidia
        
        // 1. Gemini
        try {
            $advice = $this->callGeminiChat($prompt);
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('advisor', 'gemini', 'gemini-2.5-flash', 'success', strlen($prompt) + strlen($advice), $latency, null, $advice);
            return response()->json(['advice' => $advice, 'provider' => 'Gemini']);
        } catch (\Exception $e) {
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('advisor', 'gemini', 'gemini-2.5-flash', 'failed', strlen($prompt), $latency, $e->getMessage());
            Log::warning("Gemini Advisor failed: " . $e->getMessage());
        }

        // 2. Cerebras
        $startTime = microtime(true);
        try {
            $advice = $this->callCerebrasChat($prompt);
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('advisor', 'cerebras', 'llama3.1-8b', 'success', strlen($prompt) + strlen($advice), $latency, null, $advice);
            return response()->json(['advice' => $advice, 'provider' => 'Cerebras']);
        } catch (\Exception $e) {
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('advisor', 'cerebras', 'llama3.1-8b', 'failed', strlen($prompt), $latency, $e->getMessage());
            Log::warning("Cerebras Advisor failed: " . $e->getMessage());
        }

        // 3. Groq
        $startTime = microtime(true);
        try {
            $advice = $this->callGroqChat($prompt);
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('advisor', 'groq', 'llama-3.3-70b-versatile', 'success', strlen($prompt) + strlen($advice), $latency, null, $advice);
            return response()->json(['advice' => $advice, 'provider' => 'Groq']);
        } catch (\Exception $e) {
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('advisor', 'groq', 'llama-3.3-70b-versatile', 'failed', strlen($prompt), $latency, $e->getMessage());
            Log::warning("Groq Advisor failed: " . $e->getMessage());
        }

        // 4. Cloudflare
        $startTime = microtime(true);
        try {
            $advice = $this->callCloudflareChat($prompt);
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('advisor', 'cloudflare', 'llama-3-8b-instruct', 'success', strlen($prompt) + strlen($advice), $latency, null, $advice);
            return response()->json(['advice' => $advice, 'provider' => 'Cloudflare']);
        } catch (\Exception $e) {
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('advisor', 'cloudflare', 'llama-3-8b-instruct', 'failed', strlen($prompt), $latency, $e->getMessage());
            Log::warning("Cloudflare Advisor failed: " . $e->getMessage());
        }

        // 5. Nvidia
        $startTime = microtime(true);
        try {
            $advice = $this->callNvidiaChat($prompt);
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('advisor', 'nvidia', 'llama-3.1-8b-instruct', 'success', strlen($prompt) + strlen($advice), $latency, null, $advice);
            return response()->json(['advice' => $advice, 'provider' => 'Nvidia']);
        } catch (\Exception $e) {
            $latency = (microtime(true) - $startTime) * 1000;
            $this->logUsage('advisor', 'nvidia', 'llama-3.1-8b-instruct', 'failed', strlen($prompt), $latency, $e->getMessage());
            Log::warning("Nvidia Advisor failed: " . $e->getMessage());
        }

        return response()->json(['message' => 'Seluruh layanan AI advisor sedang tidak dapat diakses saat ini. Silakan coba lagi nanti.'], 503);
    }

    private function callGeminiChat($prompt)
    {
        $apiKey = env('GEMINI_API_KEY');
        if (empty($apiKey)) throw new \Exception("Gemini API key is empty.");

        $response = Http::post("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={$apiKey}", [
            'contents' => [
                'parts' => [
                    ['text' => $prompt]
                ]
            ]
        ]);

        if ($response->failed()) {
            throw new \Exception("Gemini API HTTP Error: " . $response->body());
        }

        return $response->json('candidates.0.content.parts.0.text') ?? '';
    }

    private function callCerebrasChat($prompt)
    {
        $apiKey = env('CEREBRAS_API_KEY');
        if (empty($apiKey)) throw new \Exception("Cerebras API key is empty.");

        $response = Http::withHeaders([
            'Authorization' => "Bearer {$apiKey}",
            'Content-Type' => 'application/json'
        ])->post("https://api.cerebras.ai/v1/chat/completions", [
            'model' => 'llama3.1-8b',
            'messages' => [
                ['role' => 'user', 'content' => $prompt]
            ]
        ]);

        if ($response->failed()) {
            throw new \Exception("Cerebras API HTTP Error: " . $response->body());
        }

        return $response->json('choices.0.message.content') ?? '';
    }

    private function callGroqChat($prompt)
    {
        $apiKey = env('GROQ_API_KEY');
        if (empty($apiKey)) throw new \Exception("Groq API key is empty.");

        $response = Http::withHeaders([
            'Authorization' => "Bearer {$apiKey}",
            'Content-Type' => 'application/json'
        ])->post("https://api.groq.com/openai/v1/chat/completions", [
            'model' => 'llama-3.3-70b-versatile',
            'messages' => [
                ['role' => 'user', 'content' => $prompt]
            ]
        ]);

        if ($response->failed()) {
            throw new \Exception("Groq API HTTP Error: " . $response->body());
        }

        return $response->json('choices.0.message.content') ?? '';
    }

    private function callCloudflareChat($prompt)
    {
        $token = env('CLOUDFLARE_API_TOKEN');
        $accountId = env('CLOUDFLARE_ACCOUNT_ID', '16f22dcaab808c268f70f1118b062ab5');
        if (empty($token)) throw new \Exception("Cloudflare API token is empty.");

        $response = Http::withHeaders([
            'Authorization' => "Bearer {$token}",
            'Content-Type' => 'application/json'
        ])->post("https://api.cloudflare.com/client/v4/accounts/{$accountId}/ai/run/@cf/meta/llama-3-8b-instruct", [
            'messages' => [
                ['role' => 'user', 'content' => $prompt]
            ]
        ]);

        if ($response->failed()) {
            throw new \Exception("Cloudflare API HTTP Error: " . $response->body());
        }

        return $response->json('result.response') ?? '';
    }

    private function callNvidiaChat($prompt)
    {
        $apiKey = env('NVIDIA_API_KEY');
        if (empty($apiKey)) throw new \Exception("Nvidia API key is empty.");

        $response = Http::withHeaders([
            'Authorization' => "Bearer {$apiKey}",
            'Content-Type' => 'application/json'
        ])->post("https://integrate.api.nvidia.com/v1/chat/completions", [
            'model' => 'meta/llama-3.1-8b-instruct',
            'messages' => [
                ['role' => 'user', 'content' => $prompt]
            ]
        ]);

        if ($response->failed()) {
            throw new \Exception("Nvidia API HTTP Error: " . $response->body());
        }

        return $response->json('choices.0.message.content') ?? '';
    }
}
