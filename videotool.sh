#!/bin/bash
# Ctrl+C = berhenti total, bukan skip ke file berikutnya
trap 'echo ""; echo "Dihentikan paksa (Ctrl+C) - keluar..."; exit 130' INT TERM

compress_one() {
  read -p "Nama file video: " f
  [ -e "$f" ] || { echo "File tidak ada!"; return; }
  echo "Compress: $f"
  nice -n 19 ionice -c 3 ffmpeg -nostdin -i "$f" -threads 4 -c:v libx264 -crf 24 -preset slow -an "${f%.*}_comp.mp4" || exit 130
  echo "Selesai -> ${f%.*}_compressed.mp4"
}

compress_batch() {
  mkdir -p compressed
  for f in *.MP4 *.mp4 *.MOV *.mov; do
    [ -e "$f" ] || continue
    echo "$f" | grep -i "_compressed" > /dev/null && continue
    echo "Compress: $f"
    nice -n 19 ionice -c 3 ffmpeg -nostdin -i "$f" -threads 4 -c:v libx264 -crf 24 -preset slow -an "compressed/${f%.*}.mp4" || exit 130
  done
  echo "Selesai, cek folder compressed/"
}

rotate_one() {
  read -p "Nama file video: " f
  [ -e "$f" ] || { echo "File tidak ada!"; return; }
  read -p "Arah [1=kanan 90, 2=kiri 270] default 2: " arah
  arah=${arah:-2}
  if [ "$arah" = "1" ]; then trans=1; else trans=2; fi
  nice -n 19 ionice -c 3 ffmpeg -nostdin -noautorotate -i "$f" -threads 4 -vf "transpose=$trans" -c:v libx264 -crf 24 -preset slow -an -metadata:s:v:0 rotate=0 "${f%.*}_r.mp4" || exit 130
}

rotate_batch() {
  mkdir -p rotated
  read -p "Arah [1=kanan 90, 2=kiri 270] default 2: " arah
  arah=${arah:-2}
  if [ "$arah" = "1" ]; then trans=1; else trans=2; fi
  for f in *.MP4 *.mp4 *.MOV *.mov; do
    [ -e "$f" ] || continue
    echo "$f" | grep -i "_rotated" > /dev/null && continue
    echo "Rotate: $f"
    nice -n 19 ionice -c 3 ffmpeg -nostdin -noautorotate -i "$f" -threads 4 -vf "transpose=$trans" -c:v libx264 -crf 24 -preset slow -an -metadata:s:v:0 rotate=0 "rotated/${f%.*}.mp4" || exit 130
  done
}

cut_31_one() {
  read -p "Nama file video: " f
  [ -e "$f" ] || { echo "File tidak ada!"; return; }
  nice -n 19 ionice -c 3 ffmpeg -nostdin -i "$f" -t 31 -threads 4 -c:v libx264 -crf 24 -preset slow -an "${f%.*}_cu.mp4" || exit 130
}

cut_rotate_one() {
  read -p "Nama file video: " f
  [ -e "$f" ] || { echo "File tidak ada!"; return; }
  read -p "Arah [1=kanan 90, 2=kiri 270] default 2: " arah
  arah=${arah:-2}
  if [ "$arah" = "1" ]; then trans=1; else trans=2; fi
  nice -n 19 ionice -c 3 ffmpeg -nostdin -noautorotate -i "$f" -t 31 -threads 4 -vf "transpose=$trans" -c:v libx264 -crf 24 -preset slow -an -metadata:s:v:0 rotate=0 "${f%.*}_cr.mp4" || exit 130
}

# ... fungsi exiftool tetap sama, tidak perlu trap ffmpeg ...

while true; do
  echo ""
  echo "=== VIDEO TOOL ==="
  echo "1. Compress 1 video"
  echo "2. Compress batch 1 folder"
  echo "3. Rotate 1 video"
  echo "4. Rotate batch 1 folder"
  echo "5. Rotate 1 video (exiftool)"
  echo "6. Rotate batch (exiftool)"
  echo "7. Cut 1 video jadi max 31 detik"
  echo "8. Cut + Rotate 1 video"
  echo "0. Keluar"
  read -p "Pilih [0-8]: " pilih
  case $pilih in
    1) compress_one ;;
    2) compress_batch ;;
    3) rotate_one ;;
    4) rotate_batch ;;
    5) rotate_exif_one ;;
    6) rotate_exif_batch ;;
    7) cut_31_one ;;
    8) cut_rotate_one ;;
    0) exit 0 ;;
    *) echo "Pilihan salah!" ;;
  esac
done
