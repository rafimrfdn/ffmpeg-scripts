#!/bin/bash
# split.sh - Split foto & video ke folder-folder per batch
# Cara pakai:
#   ./split.sh -foto 500
#   ./split.sh -video 25
#   ./split.sh -foto 500 -video 25
#   ./split.sh -foto 500 --dir ./Download --copy --dry-run
#   ./split.sh --help
#
# Fitur:
# - Ekstensi lengkap & case-insensitive (JPG/jpg, PNG, HEIC, MP4/mp4, MOV, dll)
# - Aman untuk nama file ada spasi
# - Bisa -foto dan -video sekaligus
# - Mode --copy (default --move), --dry-run untuk preview
# - Folder: foto_001-260109_1030 / video_001-260109_1030

set -euo pipefail

# ---------- Default ----------
FOTO_BATCH=0
VIDEO_BATCH=0
SRC_DIR="."
MODE="move"      # move | copy
DRY_RUN=false

# ---------- Help ----------
usage() {
cat <<'EOF'
Penggunaan:
  ./split.sh -foto <jumlah> [-video <jumlah>] [opsi lain]
  ./split.sh -video <jumlah> [opsi lain]

Contoh:
  ./split.sh -foto 500
  ./split.sh -video 25
  ./split.sh -foto 500 -video 25
  ./split.sh -foto 100 --dir ~/Downloads/kamera --copy
  ./split.sh -foto 500 --dry-run

Opsi:
  -foto <n> / --foto <n> / -f <n>     Split foto, maks <n> file per folder. Default jika tanpa angka: 500
  -video <n> / --video <n> / -v <n>   Split video, maks <n> file per folder. Default jika tanpa angka: 50
  --dir <path> / -d <path>             Folder sumber (default: folder saat ini)
  --copy                               Copy, bukan pindah (default: pindah/move)
  --move                               Pindah (default)
  --dry-run / --dry                    Cuma preview, tidak pindah/copy file
  -h, --help                           Tampilkan bantuan ini

Ekstensi foto : jpg jpeg png heic heif webp gif bmp tiff tif avif dng cr2 nef arw raw
Ekstensi video: mp4 mov mkv avi webm m4v mpg mpeg 3gp wmv flv
Nama folder   : foto_001-YYMMDD_HHMMSS / video_001-YYMMDD_HHMMSS
EOF
}

# ---------- Validasi angka ----------
is_number() {
  [[ "$1" =~ ^[0-9]+$ ]] && [[ "$1" -gt 0 ]]
}

# ---------- Parsing argumen ----------
# Support -foto=500 dan -foto 500
while [[ $# -gt 0 ]]; do
  case "$1" in
    -foto|--foto|-f|--photo|--photos|-foto=*|--foto=*)
      if [[ "$1" == *=* ]]; then
        val="${1#*=}"
        shift
      elif [[ -n "${2:-}" ]] && is_number "$2"; then
        val="$2"
        shift 2
      else
        val=500
        shift
      fi
      if ! is_number "$val"; then echo "❌ Error: -foto harus angka > 0, dapat: '$val'"; exit 1; fi
      FOTO_BATCH="$val"
      ;;
    -video|--video|-v|--videos|-video=*|--video=*)
      if [[ "$1" == *=* ]]; then
        val="${1#*=}"
        shift
      elif [[ -n "${2:-}" ]] && is_number "$2"; then
        val="$2"
        shift 2
      else
        val=50
        shift
      fi
      if ! is_number "$val"; then echo "❌ Error: -video harus angka > 0, dapat: '$val'"; exit 1; fi
      VIDEO_BATCH="$val"
      ;;
    --dir|-d|--src)
      if [[ -z "${2:-}" ]]; then echo "❌ Error: --dir butuh path"; exit 1; fi
      SRC_DIR="$2"
      shift 2
      ;;
    --dir=*|--src=*)
      SRC_DIR="${1#*=}"
      shift
      ;;
    --copy)
      MODE="copy"
      shift
      ;;
    --move)
      MODE="move"
      shift
      ;;
    --dry-run|--dry)
      DRY_RUN=true
      shift
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      echo "❌ Opsi tidak dikenal: $1"
      echo ""
      usage
      exit 1
      ;;
  esac
done

# ---------- Validasi awal ----------
if [[ "$FOTO_BATCH" -eq 0 && "$VIDEO_BATCH" -eq 0 ]]; then
  echo "❌ Kamu belum pilih apa yang mau di-split."
  echo ""
  usage
  exit 1
fi

if [[ ! -d "$SRC_DIR" ]]; then
  echo "❌ Folder sumber tidak ditemukan: $SRC_DIR"
  exit 1
fi

cd "$SRC_DIR" || exit 1
SRC_DIR="."

# Timestamp sekali untuk satu run, biar folder foto & video satu grup waktu yang sama
TS=$(date +%y%m%d_%H%M%S)

# ---------- Fungsi utama ----------
# split_files <label> <batch> <prefix> <ext1> <ext2> ...
split_files() {
  local label="$1"
  local batch="$2"
  local prefix="$3"
  shift 3
  local -a exts=("$@")

  # Bangun kondisi find: -iname "*.jpg" -o -iname "*.png" ...
  local -a find_args=()
  find_args+=(-maxdepth 1 -type f \( )
  local first=true
  for ext in "${exts[@]}"; do
    if $first; then first=false; else find_args+=(-o); fi
    find_args+=(-iname "*.${ext}")
  done
  find_args+=(\) -print0)

  # Ambil file, urutkan by nama biar hasilnya konsisten tiap run
  local -a files=()
  # sort -z butuh GNU sort (Linux). Fallback kalau tidak ada.
  if sort --help 2>/dev/null | grep -q -- "-z"; then
    mapfile -d '' -t files < <(find "${find_args[@]}" 2>/dev/null | LC_ALL=C sort -z || true)
  else
    mapfile -d '' -t files < <(find "${find_args[@]}" 2>/dev/null || true)
  fi

  if [[ ${#files[@]} -eq 0 ]]; then
    echo "ℹ️  Tidak ada file $label di folder ini."
    return 0
  fi

  echo ""
  echo "📂 $label: ditemukan ${#files[@]} file, akan dibagi per $batch file (mode: $MODE)"

  local count=0
  local index=1
  local folder=""
  local total_folders=0

  for file in "${files[@]}"; do
    # file dari find diawali ./ -> bersihkan untuk display, tapi tetap aman untuk mv/cp
    local clean_file="${file#./}"

    # Bikin folder baru tiap kelipatan batch
    if (( count % batch == 0 )); then
      folder=$(printf "%s_%03d-%s" "$prefix" "$index" "$TS")
      if [[ "$DRY_RUN" == false ]]; then
        mkdir -p -- "$folder"
      fi
      ((index+=1))
      ((total_folders+=1))
    fi

    if [[ "$DRY_RUN" == true ]]; then
      echo "  [DRY-RUN] $clean_file  ->  $folder/"
    else
      if [[ "$MODE" == "copy" ]]; then
        cp -n -- "$file" "$folder/" || echo "⚠️  Gagal copy: $clean_file"
      else
        mv -n -- "$file" "$folder/" || echo "⚠️  Gagal pindah: $clean_file"
      fi
    fi
    ((count+=1))
  done

  if [[ "$DRY_RUN" == true ]]; then
    echo "✅ [DRY-RUN] $label: $count file akan masuk ke $total_folders folder"
  else
    echo "✅ Selesai $label: $count file -> $total_folders folder (contoh: ${prefix}_001-$TS)"
  fi
}

# ---------- Eksekusi ----------
echo "🚀 Split dimulai di: $(pwd)"
echo "🕒 Timestamp run: $TS"
if [[ "$DRY_RUN" == true ]]; then echo "👀 Mode: DRY-RUN (tidak ada file yang dipindah)"; fi

if [[ "$FOTO_BATCH" -gt 0 ]]; then
  split_files "Foto" "$FOTO_BATCH" "foto" jpg jpeg png heic heif webp gif bmp tiff tif avif dng cr2 nef arw raw
fi

if [[ "$VIDEO_BATCH" -gt 0 ]]; then
  split_files "Video" "$VIDEO_BATCH" "video" mp4 mov mkv avi webm m4v mpg mpeg 3gp wmv flv
fi

echo ""
echo "🎉 Beres!"


