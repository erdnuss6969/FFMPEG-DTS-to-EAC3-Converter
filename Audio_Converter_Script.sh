#!/bin/bash

# Define default values
DEFAULT_INPUT="input.mkv"
FALLBACK_BITRATE="640k"

echo "=== FFmpeg Audio Converter (EAC3, Auto-Overwrite, Batch Mode) ==="

# The loop starts here
while true; do
    echo ""
    echo "----------------------------------------------"
    # 1. Prompt for input file
    read -p "Input file (e.g. movie.mkv) [Default: $DEFAULT_INPUT]: " INPUT_FILE
    INPUT_FILE=${INPUT_FILE:-$DEFAULT_INPUT}

    # Check if the input file exists
    if [ ! -f "$INPUT_FILE" ]; then
        echo "Error: The file '$INPUT_FILE' was not found."
        # Do not hard exit on error, but restart the loop
        continue
    fi

    # Define temporary file for the conversion
    TEMP_FILE="${INPUT_FILE}.tmp.mkv"

    echo ""
    echo "Determining original audio bitrate..."

    # Read the bitrate of the first audio track using ffprobe
    ORIG_BITRATE=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")

    # Check if ffprobe returned a valid value
    if [[ -z "$ORIG_BITRATE" || "$ORIG_BITRATE" == "N/A" ]]; then
        echo "Warning: Could not read original bitrate. Using fallback value ($FALLBACK_BITRATE)."
        TARGET_BITRATE=$FALLBACK_BITRATE
    else
        # Convert bitrate to kbps for better readability
        BITRATE_KBPS=$((ORIG_BITRATE / 1000))
        TARGET_BITRATE="${BITRATE_KBPS}k"
    fi

    echo ""
    echo "Starting conversion with the following parameters:"
    echo "----------------------------------------------"
    echo "File:     $INPUT_FILE (will be overwritten!)"
    echo "Codec:    EAC3"
    echo "Bitrate:  $TARGET_BITRATE"
    echo "Title:    EAC3 - Transcoded"
    echo "----------------------------------------------"
    echo ""

    # Execute FFmpeg command and write to temporary file
    ffmpeg -i "$INPUT_FILE" -c:v copy -c:a eac3 -b:a "$TARGET_BITRATE" -metadata:s:a:0 title="EAC3 - Transcoded" "$TEMP_FILE"

    # Check if FFmpeg was successful (Exit status 0)
    if [ $? -eq 0 ]; then
        echo ""
        echo "Conversion successful. Overwriting original file..."
        # Rename temporary file to original file (overwrites the original)
        mv "$TEMP_FILE" "$INPUT_FILE"
        echo "Conversion for '$INPUT_FILE' completed!"
    else
        echo ""
        echo "Error during conversion! The original file remains untouched."
        # Delete temporary, unfinished file
        rm -f "$TEMP_FILE"
    fi

    # Prompt for the next file
    echo ""
    read -p "Do you want to convert another file? (y/n) [Default: n]: " CONTINUE_CHOICE
    CONTINUE_CHOICE=${CONTINUE_CHOICE:-n}

    # Check if the input was "y" or "Y". If not, exit the loop.
    if [[ "$CONTINUE_CHOICE" != "y" && "$CONTINUE_CHOICE" != "Y" ]]; then
        echo "Script finished. Goodbye!"
        break
    fi

    # If "y" was pressed, the script jumps back to the very top to "while true; do"
done
