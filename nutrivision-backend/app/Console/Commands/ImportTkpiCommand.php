<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

class ImportTkpiCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'tkpi:import';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Download TKPI data and seed to Pinecone Vector DB via Gemini Embedding';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        // Hilangkan batas memori PHP karena kita berurusan dengan data besar
        ini_set('memory_limit', '-1');

        $this->info('Memulai proses integrasi TKPI ke Pinecone...');

        $filePath = storage_path('app/tkpi.json');

        if (!file_exists($filePath)) {
            $this->error("File tkpi.json tidak ditemukan di: {$filePath}");
            return;
        }

        $data = json_decode(file_get_contents($filePath), true);

        if (!$data) {
            $this->error('Gagal membaca data TKPI!');
            return;
        }

        $this->info('Berhasil memuat ' . count($data) . ' baris data makanan.');

        $geminiKey = env('GEMINI_API_KEY');
        $pineconeKey = env('PINECONE_API_KEY');
        $pineconeHost = rtrim(env('PINECONE_HOST'), '/');

        if (empty($geminiKey) || empty($pineconeKey) || empty($pineconeHost)) {
            $this->error('API Key Gemini, Pinecone, atau Host belum diisi di .env');
            return;
        }

        $bar = $this->output->createProgressBar(count($data));
        $bar->start();

        $vectorsToUpsert = [];
        $progressFile = storage_path('app/tkpi_progress.txt');
        $startIndex = 0;

        if (file_exists($progressFile)) {
            $startIndex = (int) file_get_contents($progressFile);
            $this->info("Melanjutkan dari item ke-" . ($startIndex + 1));
            $bar->advance($startIndex);
        }

        // Slice data array to start from $startIndex
        $dataToProcess = array_slice($data, $startIndex);

        // Sesuai batas mutlak Free Tier Gemini: 15 Request Per Menit
        $chunkedData = array_chunk($dataToProcess, 15);

        foreach ($chunkedData as $chunkIndex => $batchItems) {
            $requests = [];
            foreach ($batchItems as $item) {
                $requests[] = [
                    "model" => "models/gemini-embedding-001",
                    "content" => [
                        "parts" => [
                            ["text" => "Nama Makanan: " . $item['nama_makanan']]
                        ]
                    ]
                ];
            }

            // Retry 3 kali dengan jeda 5 detik jika kena Rate Limit sementara
            $response = Http::retry(3, 5000)->withHeaders([
                'Content-Type' => 'application/json',
            ])->post("https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:batchEmbedContents?key={$geminiKey}", [
                        "requests" => $requests
                    ]);

            if ($response->successful()) {
                $embeddings = $response->json('embeddings');

                if ($embeddings && is_array($embeddings)) {
                    foreach ($embeddings as $i => $embeddingData) {
                        $item = $batchItems[$i];
                        $embedding = $embeddingData['values'];

                        $vectorsToUpsert[] = [
                            "id" => "tkpi-" . $item['id'],
                            "values" => $embedding,
                            "metadata" => [
                                "nama_makanan" => $item['nama_makanan'],
                                "kalori" => (float) $item['kalori'],
                                "protein" => (float) $item['protein'],
                                "lemak" => (float) $item['lemak'],
                                "karbohidrat" => (float) $item['karbohidrat']
                            ]
                        ];
                    }
                }
            } else {
                $this->error("\n[Error Gemini Batch] Gagal embed batch " . ($chunkIndex + 1) . " -> " . $response->body());
            }

            $bar->advance(count($batchItems));

            // Simpan ID terakhir untuk fitur Resume
            $lastItem = end($batchItems);
            $currentIndex = $startIndex + ($chunkIndex * 15) + count($batchItems);
            file_put_contents($progressFile, $currentIndex);

            // Upload ke Pinecone (sekarang batch size 100 per request Pinecone)
            if (count($vectorsToUpsert) > 0) {
                $pineconeResponse = Http::retry(3, 2000)->withHeaders([
                    'Api-Key' => $pineconeKey,
                    'Content-Type' => 'application/json'
                ])->post($pineconeHost . '/vectors/upsert', [
                            "vectors" => $vectorsToUpsert,
                            "namespace" => "tkpi-indonesia"
                        ]);

                if (!$pineconeResponse->successful()) {
                    $this->error("\nGagal mengirim batch ke Pinecone: " . $pineconeResponse->body());
                }

                $vectorsToUpsert = [];
            }

            // Wajib jeda 61 detik agar tidak melanggar aturan 15 Request / Menit dari Google
            $this->info("\n[Menunggu 60 detik untuk mereset kuota per-menit Gemini...]");
            sleep(61);
        }

        // Upload sisa data yang kurang dari 50
        if (count($vectorsToUpsert) > 0) {
            Http::retry(3, 2000)->withHeaders([
                'Api-Key' => $pineconeKey,
                'Content-Type' => 'application/json'
            ])->post($pineconeHost . '/vectors/upsert', [
                        "vectors" => $vectorsToUpsert,
                        "namespace" => "tkpi-indonesia"
                    ]);
        }

        $bar->finish();
        $this->newLine();
        $this->info('Sukses! Seluruh vektor TKPI berhasil dimasukkan ke Pinecone.');

        // Hapus file progress karena sudah selesai
        if (file_exists($progressFile)) {
            unlink($progressFile);
        }
    }
}
