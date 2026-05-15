import pandas as pd
import json
import os

# Konfigurasi Path
EXCEL_FILE = r"D:\Dokumenku\07. Kegiatan Non Kampus\12. Lomba UNITY UNY\929751104-Tkpi-Excel.xlsx"
OUTPUT_FILE = r"D:\Dokumenku\07. Kegiatan Non Kampus\12. Lomba UNITY UNY\nutrivision-backend\storage\app\tkpi.json"

def convert_excel_to_json():
    print(f"Membaca file Excel: {EXCEL_FILE}")
    try:
        # Membaca Excel, header di baris ke-1 (index 1)
        df = pd.read_excel(EXCEL_FILE, header=1)
        
        json_data = []
        count = 0
        
        for index, row in df.iterrows():
            # Baris data dimulai setelah row kosong/sumber, kita cek apakah ada nama makanannya
            # Di excel ini, kolom indeks 1 adalah Nama Bahan Makanan,
            # kolom indeks 4 adalah Energi (Kal),
            # kolom indeks 5 adalah Protein (g),
            # kolom indeks 6 adalah Lemak (g),
            # kolom indeks 7 adalah KH / Karbohidrat (g).
            
            # Kita akses via iloc untuk aman karena nama header mungkin tidak rapi (merged cells di excel aslinya)
            
            nama_makanan = str(row.iloc[1]).strip()
            
            # Jika nama makanan kosong atau nan atau berawalan dengan kode sumber, abaikan
            if pd.isna(row.iloc[1]) or nama_makanan.lower() == 'nan' or nama_makanan == '':
                continue
                
            # Coba parsing angka, jika bukan angka jadikan 0
            def parse_float(val):
                try:
                    return float(val)
                except:
                    return 0.0

            kalori = parse_float(row.iloc[4])
            protein = parse_float(row.iloc[5])
            lemak = parse_float(row.iloc[6])
            karbo = parse_float(row.iloc[7])
            
            # Filter baris yang benar-benar makanan (kalori > 0 atau karbo > 0)
            if kalori > 0 or protein > 0 or lemak > 0 or karbo > 0:
                count += 1
                item = {
                    "id": str(count),
                    "nama_makanan": nama_makanan.replace('\n', ' '), # Bersihkan enter
                    "kalori": kalori,
                    "protein": protein,
                    "lemak": lemak,
                    "karbohidrat": karbo
                }
                json_data.append(item)
        
        # Simpan ke storage Laravel
        os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, ensure_ascii=False, indent=4)
            
        print(f"SUKSES! Berhasil mengkonversi {len(json_data)} data makanan.")
        print(f"File disimpan di: {OUTPUT_FILE}")
        
    except Exception as e:
        print("Terjadi kesalahan:", e)

if __name__ == "__main__":
    convert_excel_to_json()
