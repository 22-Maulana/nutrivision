<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ChatbotController extends Controller
{
    public function chat(Request $request)
    {
        set_time_limit(60);
        Log::info("Chatbot endpoint hit", ['message' => $request->message]);

        $request->validate([
            'message' => 'required|string',
        ]);

        $apiKey = env('GEMINI_API_KEY');
        $model = 'gemini-2.5-flash';

        $targetProfile = $request->input('target_profile', 'Saya');
        $user = $request->user();

        $prompt = "Anda adalah NutriVision AI, asisten ahli gizi profesional untuk ibu hamil dan balita. 
        Saat ini Anda sedang berbicara dengan pengguna yang sedang memantau profil: {$targetProfile}.
        Nama Ibu: {$user->name}.
        
        Tugas Anda adalah menjawab pertanyaan user dengan ramah, informatif, dan berbasis data kesehatan yang valid. 
        Sesuaikan saran Anda berdasarkan siapa yang sedang ditanyakan (apakah Ibu sendiri atau anaknya).
        Jika user bertanya hal di luar gizi, kesehatan ibu, atau tumbuh kembang anak, ingatkan mereka secara halus bahwa Anda adalah spesialis gizi.
        
        Pertanyaan User: " . $request->message;

        try {
            $response = Http::timeout(60)->withHeaders([
                'Content-Type' => 'application/json',
            ])->post("https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$apiKey}", [
                'contents' => [
                    [
                        'parts' => [
                            ['text' => $prompt]
                        ]
                    ]
                ],
                'generationConfig' => [
                    'temperature' => 0.7,
                    'topK' => 40,
                    'topP' => 0.95,
                    'maxOutputTokens' => 4096,
                ]
            ]);

            if ($response->failed()) {
                Log::error("Chatbot AI Error Response", [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);
                return response()->json([
                    'message' => 'Gagal menghubungi AI Server.',
                    'error' => $response->json()
                ], $response->status());
            }

            $data = $response->json();
            
            // Robust parsing
            $reply = 'Maaf, saya sedang tidak bisa menjawab saat ini.';
            if (isset($data['candidates'][0]['content']['parts'][0]['text'])) {
                $reply = $data['candidates'][0]['content']['parts'][0]['text'];
            } else if (isset($data['promptFeedback']['blockReason'])) {
                $reply = "Maaf, pertanyaan Anda tidak dapat saya jawab karena alasan keamanan sistem (" . $data['promptFeedback']['blockReason'] . ").";
            }

            return response()->json([
                'reply' => $reply
            ]);

        } catch (\Exception $e) {
            Log::error("Chatbot Exception", ['message' => $e->getMessage()]);
            return response()->json([
                'message' => 'Internal Server Error',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
