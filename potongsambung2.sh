#!/bin/bash
mkdir -p hasil
for f in *.MP4 *.mp4 *.MOV *.mov; do
  [ -e "$f" ] || continue
  dur=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$f")
  t1=0
  t2=$(awk "BEGIN{print $dur*0.5-1}")
  t3=$(awk "BEGIN{print $dur*0.9}")

  # biar tidak minus kalau video pendek
  t2=$(awk "BEGIN{print ($t2<0)?0:$t2}")

  echo "Proses $f ($dur detik) -> awal 0, tengah $t2, 90% $t3"

  ffmpeg -y \
  -noautorotate -ss $t1 -t 1 -i "$f" \
  -noautorotate -ss $t2 -t 2 -i "$f" \
  -noautorotate -ss $t3 -t 2 -i "$f" \
  -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1:a=0[v]" \
  -map "[v]" -c:v libx264 -crf 23 -preset fast -metadata:s:v:0 rotate=0 "hasil/${f%.*}_5detik.mp4"
done
