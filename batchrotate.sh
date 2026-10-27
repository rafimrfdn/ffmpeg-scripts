#!/bin/bash

# Tentukan direktori target dari argumen pertama ($1), default direktori saat ini (.)
TARGET_DIR="${1:-.}"

# Pindah ke direktori target
cd "$TARGET_DIR" || { echo "Error: Direktori '$TARGET_DIR' tidak ditemukan!"; exit 1; }

echo "Masuk ke direktori: $(pwd)"
mkdir -p output

for f in *.mp4 *MP4; do
  [ -e "$f" ] || continue
  echo "Sedang memproses: $f"
  
  # Menggunakan CPU dengan batasan -threads 3 agar laptop tidak panas (aman untuk i5 Gen 11)
  # nice & ionice memastikan komputer tetap responsif untuk multitasking
  nice -n 19 ionice -c 3 ffmpeg \
    -i "$f" \
    -threads 2 \
    -vf "transpose=2" \
    -c:v libx264 -crf 20 \
    -c:a copy \
    "output/${f%.*}_.MP4"
  
  # Jeda 3 detik agar suhu CPU sempat turun sebelum file berikutnya
  sleep 3
done

echo "Semua file di $(pwd)/output berhasil diproses!"

