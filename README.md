# NutriVision 🥗📱
**Sistem Monitoring Gizi dan Tumbuh Kembang Ibu & Balita Berbasis AI**

NutriVision adalah platform kesehatan digital yang dirancang untuk membantu ibu hamil dan orang tua dalam memantau asupan gizi serta tumbuh kembang anak secara presisi. Platform ini mengintegrasikan teknologi **Computer Vision** dan **Retrieval-Augmented Generation (RAG)** untuk memberikan rekomendasi gizi yang dipersonalisasi berdasarkan dataset Tabel Komposisi Pangan Indonesia (TKPI).

---

## 🏗️ Arsitektur Sistem

NutriVision menggunakan arsitektur modern yang menghubungkan aplikasi mobile dengan infrastruktur cloud secara real-time:

- **Frontend Client**: Dikembangkan menggunakan framework Flutter untuk platform Android dan iOS.
- **Backend API**: Menggunakan Laravel 11 sebagai pusat logika bisnis, manajemen data, dan integrator AI.
- **Vector Intelligence**: Memanfaatkan Pinecone sebagai database vektor untuk pencarian data nutrisi secara semantik (RAG).
- **AI Core**: Menggunakan model Google Gemini 2.5 Flash untuk analisis gambar makanan dan asisten chatbot kesehatan.

---

## 🛠️ Spesifikasi Teknologi

### **1. Frontend (Mobile App)**
*   **Framework**: Flutter 3.x
*   **Minimum Android SDK**: 21 (Android 5.0 Lollipop)
*   **Library Utama**:
    *   `flutter_riverpod`: Manajemen state reaktif dan terstruktur.
    *   `go_router`: Sistem navigasi deklaratif.
    *   `fl_chart`: Visualisasi grafik pertumbuhan (Weight/Height).
    *   `google_generative_ai`: SDK integrasi model AI Gemini.
    *   `pdf` & `printing`: Modul pembuatan laporan gizi dalam format PDF.
    *   `shared_preferences`: Penyimpanan lokal untuk session token dan cache.

### **2. Backend (API Server)**
*   **Framework**: Laravel 11 (PHP 8.3)
*   **Database Relasional**: MySQL
*   **Vector Database**: Pinecone (Namespace: `tkpi-indonesia`)
*   **Autentikasi**: Laravel Sanctum (Token-based Authentication)
*   **Production URL**: [be-nutrivision.maulanaap.my.id](https://be-nutrivision.maulanaap.my.id)

---

## 🧠 Logika Algoritma AI & RAG

Aplikasi ini mengimplementasikan alur **Retrieval-Augmented Generation (RAG)** untuk memastikan akurasi data gizi:

1.  **Analisis Gambar**: Gemini Vision mendeteksi jenis makanan dari foto yang diunggah.
2.  **Pencarian Semantik**: Sistem melakukan embedding pada nama makanan dan mencari kecocokan data nutrisi pada **Pinecone** (Dataset TKPI).
3.  **Injeksi Konteks**: Data nutrisi resmi hasil pencarian digabungkan dengan profil medis pengguna (status kehamilan, alergi, usia anak).
4.  **Generasi Final**: Model AI menghitung estimasi kalori dan memberikan rekomendasi personal (Dianjurkan/Perhatian/Hindari) berdasarkan profil pengguna.

---

## 🔗 Dokumentasi API

Seluruh komunikasi data menggunakan format JSON melalui Base URL: `https://be-nutrivision.maulanaap.my.id/api`

### **Modul Autentikasi**
- `POST /register`: Pendaftaran pengguna baru.
- `POST /verify-otp`: Verifikasi akun melalui kode OTP.
- `POST /login`: Masuk ke sistem dan mendapatkan token.

### **Modul Profil & Anak**
- `GET /profile`: Mengambil data profil lengkap pengguna.
- `PUT /profile/mother`: Memperbarui data medis ibu (status kehamilan, alergi).
- `POST /profile/child`: Menambah profil anak baru.

### **Modul AI & Riwayat**
- `POST /scan`: Proses analisis makanan menggunakan sistem RAG.
- `GET /food-logs`: Mengambil riwayat konsumsi makanan.
- `GET /dashboard/summary`: Mendapatkan ringkasan capaian gizi harian.
- `POST /chatbot`: Interaksi dengan NutriBot (Asisten AI).

### **Modul Pertumbuhan**
- `GET /growth-records`: Mengambil data histori berat dan tinggi badan.
- `POST /growth-records`: Menyimpan data pengukuran pertumbuhan baru.

---

## 🚀 Panduan Penggunaan

1.  **Pendaftaran Akun**: Pengguna mendaftar dan memverifikasi profil medis awal.
2.  **Monitoring Gizi**: Ambil foto makanan melalui menu Scan. AI akan secara otomatis menghitung nutrisi dan memberikan saran berdasarkan kondisi kesehatan pengguna (misal: "Hindari" jika terdapat bahan pemicu alergi).
3.  **Pemantauan Tumbuh Kembang**: Input data berat dan tinggi badan secara berkala untuk melihat grafik tren sesuai standar WHO.
4.  **Ekspor Laporan**: Gunakan fitur ekspor PDF di halaman profil untuk mendapatkan laporan kesehatan lengkap yang siap dikonsultasikan ke tenaga medis.

---
*Proyek ini dikembangkan untuk **UNITY #14 - UNESA** | NutriVision - Solusi Inovatif Kesehatan Ibu & Anak.*
