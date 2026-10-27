#!/bin/bash

# Check if a filename argument was provided
if [ -z "$1" ]; then
    echo "Error: No file specified."
    echo "Usage: rotateme.sh filename.mp4"
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
OUTPUT_FILE="${FILENAME}_r.${EXTENSION}"

echo "Rotating '$INPUT_FILE' by 90° clockwise..."

# FFmpeg command: transpose=1 (90° clockwise), -c:a copy (preserves audio quality/speed)
ffmpeg -i "$INPUT_FILE" -threads 2 -vf "transpose=2" -c:a copy "$OUTPUT_FILE"

# Check if ffmpeg completed successfully
if [ $? -eq 0 ]; then
    echo "Success! Saved as: $OUTPUT_FILE"
else
    echo "Error: FFmpeg failed to process the video."
    exit 1
fi
