#!/bin/bash

# Check if a filename argument was provided
if [ -z "$1" ]; then
    echo "Error: No file specified."
    echo "Usage: cutandrotate.sh filename.mp4"
    exit 1
fi

INPUT_FILE="$1"

# Check if the file actually exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' not found."
    exit 1
fi

# Extract filename and extension
EXTENSION="${INPUT_FILE##*.}"
FILENAME="${INPUT_FILE%.*}"
OUTPUT_FILE="${FILENAME}_cr.${EXTENSION}"

echo "Processing '$INPUT_FILE' (Cutting to 30s max & Rotating 90° clockwise)..."

# FFmpeg command:
# -t 30 (caps duration at 30 seconds)
# -vf "transpose=1" (rotates 90° clockwise)
# -c:v libx264 (re-encodes video for precise cut and filter support)
# -c:a copy (copies audio without re-encoding to save time)
ffmpeg -i "$INPUT_FILE" -threads 2 -t 31 -vf "transpose=2" -c:v libx264 -c:a copy "$OUTPUT_FILE"

# Check if ffmpeg completed successfully
if [ $? -eq 0 ]; then
    echo "Success! Saved as: $OUTPUT_FILE"
else
    echo "Error: FFmpeg failed to process the video."
    exit 1
fi
