# NutriVision Backend API Documentation

Selamat datang di repositori Backend NutriVision. Backend ini dibangun menggunakan framework **Laravel** dan berfungsi sebagai pusat data dan logika bisnis untuk aplikasi mobile NutriVision. Sistem ini menangani autentikasi pengguna, manajemen rekam medis/pertumbuhan anak, pencatatan asupan gizi harian (Food Logs), serta manajemen profil ibu dan anak.

---

## 1. Alur Sistem Backend (Backend Flow)

Sistem backend NutriVision menggunakan pendekatan RESTful API dengan alur kerja utama sebagai berikut:

1. **Autentikasi & Keamanan (Sanctum)**
   - Semua endpoint yang mengelola data pribadi diamankan menggunakan **Laravel Sanctum**.
   - Pengguna (Ibu) dapat mendaftar (Register), masuk secara manual (Login), atau menggunakan autentikasi Google (Google Login).
   - Saat pengguna berhasil login atau mendaftar, sistem akan mengembalikan `token` yang harus disertakan dalam _Header_ (`Authorization: Bearer <token>`) untuk setiap request ke endpoint yang diproteksi.
   - Saat proses registrasi berhasil, sistem juga akan **secara otomatis membuatkan Profil Ibu (Mother Profile)**.

2. **Manajemen Profil**
   - Setelah masuk, pengguna dapat menambahkan **Profil Anak (Child Profile)** untuk dipantau pertumbuhan dan asupan gizinya.

3. **Pencatatan Gizi (Food Logging)**
   - Sistem menyediakan fungsionalitas untuk mencatat asupan makanan harian.
   - Target asupan bisa ditujukan kepada Ibu atau Anak (`target_type`).
   - Terdapat endpoint untuk mendapatkan **Ringkasan Hari Ini (Dashboard Summary)** yang menghitung total kalori, protein, lemak, dan karbohidrat dari makanan yang dikonsumsi hari ini.

4. **Pemantauan Pertumbuhan (Growth Tracking)**
   - Pengguna dapat mencatat berat dan tinggi badan anak secara berkala (Growth Records).
   - Data ini kemudian dapat ditarik untuk divisualisasikan menjadi grafik pertumbuhan di sisi Frontend.

---

## 2. Struktur Folder (Folder Structure)

Berikut adalah struktur direktori penting di dalam backend ini:

```text
nutrivision-backend/
├── app/
│   ├── Http/
│   │   └── Controllers/API/    # Berisi semua logika API endpoint (AuthController, FoodLogController, dll)
│   └── Models/                 # Berisi representasi tabel database (User, ChildProfile, FoodLog, dll)
├── database/
│   ├── migrations/             # Skema database untuk pembuatan tabel secara otomatis
│   └── seeders/                # Data dummy awal (jika ada)
├── routes/
│   └── api.php                 # Pintu masuk utama (routing) untuk semua endpoint REST API
├── .env                        # File konfigurasi utama (koneksi database, dll)
└── README.md                   # Dokumentasi backend (file ini)
```

---

## 3. Dokumentasi Endpoint Keseluruhan

> **Catatan Penting:** Semua endpoint di bawah bagian "Protected Endpoints" memerlukan Header HTTP berikut:
> - `Accept: application/json`
> - `Authorization: Bearer {TOKEN}`

### A. Authentication (Public Endpoints)

#### 1. Register User
- **Endpoint:** `POST /api/register`
- **Tujuan:** Mendaftarkan akun baru dan otomatis membuat Mother Profile.
- **Payload (JSON):**
  ```json
  {
      "name": "Nama Ibu",
      "email": "ibu@email.com",
      "password": "password123"
  }
  ```

#### 2. Login User
- **Endpoint:** `POST /api/login`
- **Tujuan:** Otentikasi pengguna menggunakan email dan password.
- **Payload (JSON):**
  ```json
  {
      "email": "ibu@email.com",
      "password": "password123"
  }
  ```

#### 3. Google Login
- **Endpoint:** `POST /api/auth/google`
- **Tujuan:** Otentikasi atau pendaftaran menggunakan akun Google.
- **Payload (JSON):**
  ```json
  {
      "email": "ibu@gmail.com",
      "google_id": "1234567890",
      "name": "Nama Ibu",
      "avatar": "https://url.to/avatar.jpg"
  }
  ```

---

### B. User & Profile (Protected Endpoints)

#### 4. Get Current User
- **Endpoint:** `GET /api/user`
- **Tujuan:** Mendapatkan data user yang sedang login beserta token yang aktif.

#### 5. Tambah Profil Anak (Store Child Profile)
- **Endpoint:** `POST /api/profile/child`
- **Tujuan:** Menambahkan profil anak untuk pengguna yang sedang login.
- **Payload (JSON):**
  ```json
  {
      "name": "Nama Anak",
      "birth_date": "2023-01-01",
      "gender": "L", 
      "allergies": ["Susu Sapi", "Kacang"] 
  }
  ```
  *(Catatan: `gender` hanya menerima "L" untuk Laki-laki atau "P" untuk Perempuan)*

---

### C. Food Logs (Pencatatan Makanan - Protected Endpoints)

#### 6. Catat Makanan (Store Food Log)
- **Endpoint:** `POST /api/food-logs`
- **Tujuan:** Menyimpan catatan makanan baru.
- **Payload (JSON):**
  ```json
  {
      "target_type": "CHILD", 
      "target_id": "{UUID_CHILD_ATAU_MOTHER}",
      "meal_time": "2026-05-08 12:00:00",
      "food_name_detected": "Nasi Goreng",
      "recommendation_status": "Sangat Baik",
      "calories_kcal": 350,
      "protein_g": 12,
      "fat_g": 10,
      "carbs_g": 40,
      "notes": "Makan siang"
  }
  ```
  *(Catatan: `target_type` harus "MOTHER" atau "CHILD")*

#### 7. Ringkasan Nutrisi Hari Ini (Dashboard Summary)
- **Endpoint:** `GET /api/dashboard/summary`
- **Tujuan:** Mendapatkan total makronutrisi harian dan daftar riwayat makanan hari ini.

#### 8. Lihat Semua Riwayat Makanan (Get All Food Logs)
- **Endpoint:** `GET /api/food-logs`
- **Tujuan:** Mengambil semua riwayat makanan pengguna, diurutkan dari yang terbaru.

#### 9. Update Catatan Makanan (Update Food Log)
- **Endpoint:** `PUT /api/food-logs/{id}`
- **Tujuan:** Memperbarui _notes_ pada riwayat makanan tertentu.
- **Payload (JSON):**
  ```json
  {
      "notes": "Dihabiskan separuh saja"
  }
  ```

#### 10. Hapus Catatan Makanan (Delete Food Log)
- **Endpoint:** `DELETE /api/food-logs/{id}`
- **Tujuan:** Menghapus riwayat makanan berdasarkan ID.

---

### D. Pemantauan Pertumbuhan (Growth Records - Protected Endpoints)

#### 11. Catat Pertumbuhan (Store Growth Record)
- **Endpoint:** `POST /api/growth-records`
- **Tujuan:** Menyimpan data tinggi dan berat badan anak terbaru.
- **Payload (JSON):**
  ```json
  {
      "child_id": "{UUID_CHILD}",
      "measured_at": "2026-05-08",
      "weight_kg": 10.5,
      "height_cm": 80.2
  }
  ```

#### 12. Lihat Riwayat Pertumbuhan Anak (Get Growth Records)
- **Endpoint:** `GET /api/growth-records/{child_id}`
- **Tujuan:** Mengambil seluruh riwayat pemantauan tinggi dan berat badan anak berdasarkan ID Anak.

---

## 4. Cara Pengujian Endpoint

Untuk menguji API backend NutriVision, Anda dapat menggunakan alat seperti **Postman**, **Insomnia**, atau ekstensi VS Code seperti **Thunder Client**.

### Persiapan Server Lokal
1. Pastikan Anda berada di dalam folder `nutrivision-backend`.
2. Jalankan server lokal Laravel dengan command:
   ```bash
   php artisan serve
   ```
   Secara default, API akan berjalan di `http://localhost:8000`.

### Langkah-langkah Pengujian (Contoh via Postman)

1. **Atur Header Global (Penting!)**
   Setiap request di Postman wajib mengatur header berikut pada tab **Headers**:
   - Key: `Accept`, Value: `application/json`
   - Key: `Content-Type`, Value: `application/json`

2. **Lakukan Register / Login Terlebih Dahulu**
   - Buat request baru dengan method **POST** ke `http://localhost:8000/api/register` (atau login).
   - Masukkan JSON payload di tab **Body -> raw -> JSON**.
   - Kirim request. Di dalam response JSON, Anda akan mendapatkan sebuah string `token`. **Copy token tersebut.**

3. **Gunakan Token untuk Endpoint Lainnya**
   - Untuk menguji endpoint seperti `/api/dashboard/summary` (yang membutuhkan otentikasi), buat request baru.
   - Pindah ke tab **Authorization** di Postman.
   - Pilih Type: **Bearer Token**.
   - Paste token yang telah di-copy sebelumnya ke kolom **Token**.
   - Klik Send. Anda sekarang seharusnya mendapatkan respon valid dengan kode HTTP 200 (Bukan 401 Unauthorized).
