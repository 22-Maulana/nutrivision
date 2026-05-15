<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use App\Models\FoodLog;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

use App\Models\MotherProfile;
use App\Models\ChildProfile;

class ScanController extends Controller
{
    public function scan(Request $request)
    {
        // Increase execution time for complex AI analysis
        set_time_limit(180);

        $request->validate([
            'image' => 'required|image|mimes:jpeg,png,jpg|max:5120',
            'target_type' => 'required|in:MOTHER,CHILD',
            'target_id' => 'required|uuid',
            'notes' => 'nullable|string'
        ]);

        $imagePath = $request->file('image')->getPathname();
        $mimeType = $request->file('image')->getMimeType();
        $base64Image = base64_encode(file_get_contents($imagePath));

        $geminiKey = env('GEMINI_API_KEY');
        $pineconeKey = env('PINECONE_API_KEY');
        $pineconeHost = rtrim(env('PINECONE_HOST'), '/');

        // Fetch Target Profile Info for Personalized Prompt
        $profileInfo = "";
        $targetName = "";
        if ($request->target_type === 'MOTHER') {
            $profile = MotherProfile::where('id', $request->target_id)->first();
            if ($profile) {
                $targetName = $profile->full_name;
                $profileInfo = "Subjek: Ibu (Status: {$profile->status}). ";
                if (!empty($profile->allergies)) {
                    $profileInfo .= "Alergi: " . implode(', ', $profile->allergies) . ". ";
                }
            }
        } else {
            $profile = ChildProfile::where('id', $request->target_id)->first();
            if ($profile) {
                $targetName = $profile->name;
                $age = Carbon::parse($profile->birth_date)->diffInMonths(Carbon::now());
                $profileInfo = "Subjek: Anak (Usia: {$age} bulan). ";
                if (!empty($profile->allergies)) {
                    $profileInfo .= "Alergi: " . implode(', ', $profile->allergies) . ". ";
                }
            }
        }

        $userNotes = $request->input('notes', '');

        // ==========================================
        // Tahap 1: Deteksi Makanan dengan Gemini Vision
        // ==========================================
        $visionResponse = Http::timeout(60)->withHeaders([
            'Content-Type' => 'application/json'
        ])->post("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={$geminiKey}", [
                    "contents" => [
                        [
                            "parts" => [
                                ["text" => "Identify the specific Indonesian foods in this image. Return ONLY the names of the food separated by commas. E.g. 'Nasi Putih, Ayam Goreng, Sambal'"],
                                [
                                    "inlineData" => [
                                        "mimeType" => $mimeType,
                                        "data" => $base64Image
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]);

        if (!$visionResponse->successful()) {
            Log::error("Gemini Vision Error: " . $visionResponse->body());
            return response()->json(['error' => 'Gagal mendeteksi gambar dengan AI.'], 500);
        }

        $detectedFoodsText = $visionResponse->json('candidates.0.content.parts.0.text');
        $detectedFoodsText = trim($detectedFoodsText);

        if (!$detectedFoodsText) {
            return response()->json(['error' => 'Tidak ada makanan yang terdeteksi.'], 400);
        }

        // ==========================================
        // Tahap 2: Embedding Teks Makanan
        // ==========================================
        $embedResponse = Http::timeout(30)->withHeaders([
            'Content-Type' => 'application/json'
        ])->post("https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent?key={$geminiKey}", [
                    "model" => "models/gemini-embedding-001",
                    "content" => [
                        "parts" => [
                            ["text" => "Nama Makanan: " . $detectedFoodsText]
                        ]
                    ]
                ]);

        if (!$embedResponse->successful()) {
            return response()->json(['error' => 'Gagal membuat vektor teks.'], 500);
        }

        $embedding = $embedResponse->json('embedding.values');

        // ==========================================
        // Tahap 3: Query ke Pinecone (RAG)
        // ==========================================
        $pineconeResponse = Http::timeout(30)->withHeaders([
            'Api-Key' => $pineconeKey,
            'Content-Type' => 'application/json'
        ])->post($pineconeHost . '/query', [
                    "namespace" => "tkpi-indonesia",
                    "vector" => $embedding,
                    "topK" => 3, // Ambil 3 data TKPI paling relevan
                    "includeMetadata" => true
                ]);

        $tkpiContext = "";
        if ($pineconeResponse->successful()) {
            $matches = $pineconeResponse->json('matches') ?? [];
            foreach ($matches as $match) {
                $meta = $match['metadata'];
                $tkpiContext .= "- {$meta['nama_makanan']}: Kalori {$meta['kalori']} kkal, Protein {$meta['protein']}g, Lemak {$meta['lemak']}g, Karbo {$meta['karbohidrat']}g per 100g.\n";
            }
        }

        // ==========================================
        // Tahap 4: Final Generation (Perhitungan Kalori)
        // ==========================================
        $prompt = "You are an expert nutritionist. I will provide an image of a meal, official nutritional data (TKPI), and user profile context.
        
        USER PROFILE CONTEXT:
        {$profileInfo}
        
        USER NOTES ABOUT THIS MEAL:
        \"{$userNotes}\"

        TKPI Data (per 100g):
        {$tkpiContext}
        
        Task:
        1. Identify foods in the image.
        2. Estimate total weight and calculate nutrients based on TKPI.
        3. Provide personalized recommendation status (DIANJURKAN|PERHATIAN|HINDARI).
           *CRITICAL*: If the food contains ingredients listed in the USER's allergies, you MUST mark it as HINDARI and explain why in the notes.
           *CONTEXT*: Consider the user's status (pregnant/breastfeeding) or the child's age (MPASI suitability).
        4. Add notes in Indonesian explaining why it is recommended or not, and any tips. Mention the user/child name ($targetName) if appropriate.

        Return ONLY a JSON object:
        {
          \"food_name_detected\": \"string\",
          \"notes\": \"string\",
          \"recommendation_status\": \"DIANJURKAN|PERHATIAN|HINDARI\",
          \"calories_kcal\": float,
          \"protein_g\": float,
          \"fat_g\": float,
          \"carbs_g\": float
        }";


        $ragResponse = Http::timeout(60)->withHeaders([
            'Content-Type' => 'application/json'
        ])->post("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={$geminiKey}", [
                    "contents" => [
                        [
                            "parts" => [
                                ["text" => $prompt],
                                [
                                    "inlineData" => [
                                        "mimeType" => $mimeType,
                                        "data" => $base64Image
                                    ]
                                ]
                            ]
                        ]
                    ],
                    "generationConfig" => [
                        "responseMimeType" => "application/json"
                    ]
                ]);

        if (!$ragResponse->successful()) {
            Log::error("Gemini Analysis Error: " . $ragResponse->body());
            return response()->json(['error' => 'Gagal menganalisis gizi.'], 500);
        }

        $resultJsonString = $ragResponse->json('candidates.0.content.parts.0.text');
        $nutritionData = json_decode($resultJsonString, true);

        if (!$nutritionData) {
            return response()->json(['error' => 'Gagal mengurai respons AI.'], 500);
        }

        // ==========================================
        // Tahap 5: Simpan ke Database
        // ==========================================
        $path = $request->file('image')->store('public/food_logs');
        $photoUrl = asset('storage/' . str_replace('public/', '', $path));

        $foodLog = FoodLog::create([
            'user_id' => $request->user()->id,
            'target_type' => $request->target_type,
            'target_id' => $request->target_id,
            'meal_time' => Carbon::now(),
            'photo_url' => $photoUrl,
            'food_name_detected' => $nutritionData['food_name_detected'] ?? $detectedFoodsText,
            'notes' => $nutritionData['notes'] ?? '',
            'recommendation_status' => $nutritionData['recommendation_status'] ?? 'MODERATE',
            'calories_kcal' => $nutritionData['calories_kcal'] ?? 0,
            'protein_g' => $nutritionData['protein_g'] ?? 0,
            'fat_g' => $nutritionData['fat_g'] ?? 0,
            'carbs_g' => $nutritionData['carbs_g'] ?? 0,
            'fiber_g' => 0,
            'iron_mg' => 0,
            'calcium_mg' => 0,
        ]);

        return response()->json([
            'message' => 'Analisis berhasil',
            'data' => $foodLog
        ], 201);
    }
}
