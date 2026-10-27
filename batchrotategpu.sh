#!/usr/bin/env bash

# ============================================================
# Rotasi video dengan Intel Quick Sync (GPU) + fallback CPU
# Folder output dibuat di masing-masing folder video.
# ============================================================

set -u
shopt -s nullglob

TARGET_DIR="${1:-.}"

# Pastikan folder target valid.
if ! cd "$TARGET_DIR"; then
    echo "Error: Direktori '$TARGET_DIR' tidak ditemukan!"
    exit 1
fi

TARGET_DIR="$(pwd)"

# Periksa FFmpeg.
if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "Error: FFmpeg belum terpasang."
    exit 1
fi

# Periksa dukungan encoder.
ENCODERS="$(ffmpeg -hide_banner -encoders 2>/dev/null || true)"

if grep -qE '[[:space:]]h264_qsv([[:space:]]|$)' <<< "$ENCODERS"; then
    QSV_AVAILABLE=1
else
    QSV_AVAILABLE=0
fi

echo "Folder utama : $TARGET_DIR"
echo "Encoder QSV  : $([ "$QSV_AVAILABLE" -eq 1 ] && echo tersedia || echo tidak tersedia)"
echo

TOTAL=0
GPU_SUCCESS=0
CPU_SUCCESS=0
FAILED=0

# Memproses folder-folder langsung di dalam folder utama.
for dir in */; do
    [ -d "$dir" ] || continue

    # Jangan memproses folder output.
    [ "${dir%/}" = "output" ] && continue

    # Kumpulkan video MP4, tanpa membedakan kapitalisasi ekstensi.
    files=("$dir"*.mp4 "$dir"*.MP4 "$dir"*.Mp4 "$dir"*.mP4)

    [ "${#files[@]}" -gt 0 ] || continue

    echo "========================================"
    echo "Folder: $dir"
    echo "========================================"

    mkdir -p "${dir}output" || {
        echo "Gagal membuat folder output: $dir"
        FAILED=$((FAILED + ${#files[@]}))
        continue
    }

    for f in "${files[@]}"; do
        [ -f "$f" ] || continue

        filename="${f##*/}"
        basename="${filename%.*}"
        output="${dir}output/${basename}_.MP4"

        # File sementara mencegah output gagal dianggap berhasil.
        tmp="${output%.MP4}.tmp.$$.MP4"

        TOTAL=$((TOTAL + 1))

        echo
        echo "[$TOTAL] Memproses: $f"

        # Bersihkan sisa file sementara dari percobaan sebelumnya.
        rm -f -- "$tmp"

        success=0

        # ----------------------------------------------------
        # Percobaan pertama: Intel Quick Sync Video (QSV).
        # transpose berjalan pada jalur filter FFmpeg biasa;
        # encoding video menggunakan encoder hardware QSV.
        # ----------------------------------------------------
        if [ "$QSV_AVAILABLE" -eq 1 ]; then
            echo "Mencoba encoder GPU Intel QSV..."

            if nice -n 19 ionice -c 3 ffmpeg \
                -hide_banner -loglevel error -nostdin -y \
                -i "$f" \
                -threads 2 \
                -map 0:v:0 -map '0:a?' \
                -vf "transpose=2,format=nv12" \
                -c:v h264_qsv \
                -global_quality 23 \
                -c:a copy \
                "$tmp"
            then
                success=1
                GPU_SUCCESS=$((GPU_SUCCESS + 1))
                echo "Berhasil menggunakan Intel QSV."
            else
                echo "QSV gagal. Beralih ke encoder CPU..."
                rm -f -- "$tmp"
            fi
        else
            echo "QSV tidak tersedia. Menggunakan CPU."
        fi

        # ----------------------------------------------------
        # Fallback CPU: H.264 menggunakan libx264.
        # ----------------------------------------------------
        if [ "$success" -eq 0 ]; then
            if nice -n 19 ionice -c 3 ffmpeg \
                -hide_banner -loglevel error -nostdin -y \
                -threads 2 \
                -i "$f" \
                -map 0:v:0 -map '0:a?' \
                -vf "transpose=2" \
                -c:v libx264 \
                -preset veryfast \
                -crf 23 \
                -threads 2 \
                -c:a copy \
                "$tmp"
            then
                success=1
                CPU_SUCCESS=$((CPU_SUCCESS + 1))
                echo "Berhasil menggunakan CPU."
            else
                echo "GAGAL memproses: $f"
                FAILED=$((FAILED + 1))
                rm -f -- "$tmp"
            fi
        fi

        # Hanya pindahkan hasil jika FFmpeg berhasil.
        if [ "$success" -eq 1 ]; then
            if mv -f -- "$tmp" "$output"; then
                echo "Output: $output"
            else
                echo "Gagal menyimpan output: $output"
                FAILED=$((FAILED + 1))
                rm -f -- "$tmp"
            fi
        fi

        # Jeda 3 detik setelah setiap video.
        sleep 3
    done
done

echo
echo "========================================"
echo "SELESAI"
echo "========================================"
echo "Total video diproses : $TOTAL"
echo "Berhasil dengan GPU  : $GPU_SUCCESS"
echo "Berhasil dengan CPU  : $CPU_SUCCESS"
echo "Gagal                : $FAILED"
