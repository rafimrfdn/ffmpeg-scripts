#!/bin/bash
for f in *.MP4 *.mp4 *.MOV *.mov; do
  [ -e "$f" ] || continue
  echo "Compressing: $f"
  nice -n 19 ionice -c 3 ffmpeg -i "$f" -threads 4 -c:v libx264 -crf 24 -preset slow -an /tmp/tmp.mp4 && mv /tmp/tmp.mp4 "$f"
  # sleep 20
done
