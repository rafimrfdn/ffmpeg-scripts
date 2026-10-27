#!/bin/bash

# Folder utama dari argumen pertama.
# Jika tidak diberikan, gunakan direktori saat ini.
TARGET_DIR="${1:-.}"

# Pastikan folder utama valid.
if ! cd "$TARGET_DIR"; then
    echo "Error: Direktori '$TARGET_DIR' tidak ditemukan!"
    exit 1
fi

echo "Folder utama: $(pwd)"

# Proses video di setiap subfolder langsung di bawah folder utama.
for dir in */; do
    [ -d "$dir" ] || continue

    # Lewati folder output agar tidak diproses ulang.
    [ "$dir" = "output/" ] && continue

    echo
    echo "Memeriksa folder: $dir"

    # Buat folder output di dalam subfolder tersebut.
    mkdir -p "${dir}output"

    found=0

    # Cari file MP4, termasuk ekstensi .mp4 dan .MP4.
    for f in "$dir"*.[mM][pP]4; do
        [ -f "$f" ] || continue

        found=1
        filename="${f##*/}"
        basename="${filename%.*}"

        echo "Sedang memproses: $f"

        # Rotasi video 90 derajat berlawanan arah jarum jam.
        nice -n 19 ionice -c 3 ffmpeg \
            -i "$f" \
            -threads 2 \
            -vf "transpose=2" \
            -c:a copy \
            "${dir}output/${basename}_.MP4"

        # Jeda 3 detik setelah setiap video.
        sleep 3
    done

    if [ "$found" -eq 0 ]; then
        echo "Tidak ada video MP4 di folder $dir"
    fi
done

echo
echo "Semua folder selesai diperiksa."
