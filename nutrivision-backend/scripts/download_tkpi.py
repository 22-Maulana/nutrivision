import pandas as pd
import requests
import json
import os

# Konfigurasi Path Output
OUTPUT_FILE = '../storage/app/tkpi.json'

def fetch_community_tkpi():
    """
    Fungsi ini akan mencoba mendownload dataset TKPI (versi CSV) 
    yang sudah dibersihkan oleh komunitas Open Source / Bangkit Academy di Github.
    """
    print("Mencoba mendownload dataset TKPI dari repositori Open Source...")
    # Ini adalah salah satu contoh URL Raw CSV dataset nutrisi pangan lokal.
    # Jika URL ini kelak mati, Anda harus menggunakan mode file lokal (parse_local_csv).
    url = "https://raw.githubusercontent.com/zakialawi/tkpi-indonesia/main/tkpi_clean.csv" 
    
    try:
        response = requests.get(url)
        if response.status_code == 200:
            # Simpan sementara
            with open('temp_tkpi.csv', 'wb') as f:
                f.write(response.content)
            
            print("Download berhasil. Mulai memparsing data...")
            parse_local_csv('temp_tkpi.csv')
            os.remove('temp_tkpi.csv') # Hapus file temporary
        else:
            print("Gagal mendownload dari Github. Status:", response.status_code)
            print("Silakan download manual file TKPI dan gunakan fungsi parse_local_csv().")
    except Exception as e:
        print("Error jaringan:", e)

def parse_local_csv(file_path):
    """
    Membaca file CSV/Excel TKPI dan mengubah formatnya menjadi JSON 
    yang persis dibutuhkan oleh Laravel (id, nama_makanan, kalori, protein, lemak, karbohidrat)
    """
    try:
        # Jika file asli berformat excel, ganti pd.read_csv menjadi pd.read_excel(file_path)
        df = pd.read_csv(file_path)
        
        # Asumsi: Kolom di dataset mungkin bernama bahasa indonesia atau inggris,
        # kita coba mapping kolomnya. Anda mungkin perlu menyesuaikan nama kolom di bawah 
        # dengan nama kolom dari file CSV asli yang Anda miliki.
        
        # Mengubah nama kolom menjadi huruf kecil semua untuk mempermudah pencocokan
        df.columns = [str(col).lower().strip() for col in df.columns]
        
        # Mencari kolom yang relevan (Fleksibel terhadap penamaan kolom)
        col_nama = [c for c in df.columns if 'nama' in c or 'food' in c][0]
        col_kalori = [c for c in df.columns if 'energi' in c or 'kalori' in c or 'energy' in c][0]
        col_protein = [c for c in df.columns if 'protein' in c][0]
        col_lemak = [c for c in df.columns if 'lemak' in c or 'fat' in c][0]
        col_karbo = [c for c in df.columns if 'karbo' in c or 'carbo' in c][0]

        json_data = []
        
        print(f"Total data ditemukan: {len(df)} baris. Memproses...")
        
        for index, row in df.iterrows():
            # Bersihkan nilai NaN / Kosong menjadi 0
            kalori = float(row[col_kalori]) if pd.notna(row[col_kalori]) else 0.0
            protein = float(row[col_protein]) if pd.notna(row[col_protein]) else 0.0
            lemak = float(row[col_lemak]) if pd.notna(row[col_lemak]) else 0.0
            karbo = float(row[col_karbo]) if pd.notna(row[col_karbo]) else 0.0
            
            # Cek jika makanan valid (ada namanya)
            if pd.notna(row[col_nama]) and str(row[col_nama]).strip() != "":
                item = {
                    "id": str(index + 1),
                    "nama_makanan": str(row[col_nama]).strip(),
                    "kalori": kalori,
                    "protein": protein,
                    "lemak": lemak,
                    "karbohidrat": karbo
                }
                json_data.append(item)
                
        # Buat folder jika belum ada
        os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
        
        # Simpan ke storage Laravel
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, ensure_ascii=False, indent=4)
            
        print(f"SUKSES! {len(json_data)} data TKPI telah disimpan di: {OUTPUT_FILE}")
        print("Sekarang Anda bisa menjalankan 'php artisan tkpi:import' di terminal Laravel Anda.")

    except Exception as e:
        print("Terjadi kesalahan saat memparsing CSV:", e)

if __name__ == "__main__":
    print("=== SCRIPT GENERATOR TKPI ===")
    print("1. Coba download dari Komunitas (Github)")
    print("2. Parsing dari file CSV/Excel lokal Anda")
    
    pilihan = input("Pilih mode (1/2): ")
    
    if pilihan == '1':
        fetch_community_tkpi()
    elif pilihan == '2':
        path = input("Masukkan lokasi file CSV Anda (contoh: data_tkpi.csv): ")
        if os.path.exists(path):
            parse_local_csv(path)
        else:
            print("File tidak ditemukan!")
    else:
        print("Pilihan tidak valid.")
