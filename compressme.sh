#!/bin/bash
# cara pakai: ./compress_1.sh DSC_6368.MP4

f="$1"

if [ -z "$f" ]; then
  echo "Pakai: $0 namafile.mp4"
  exit 1
fi

if [ ! -e "$f" ]; then
  echo "File tidak ketemu: $f"
  exit 1
fi

echo "Compressing: $f"
nice -n 19 ionice -c 3 ffmpeg -y -i "$f" -threads 5 -c:v libx264 -crf 24 -preset slow -an "${f%.*}_s.mp4"
echo "Selesai: $f"
