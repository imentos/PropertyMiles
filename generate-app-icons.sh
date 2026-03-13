#!/bin/bash

# Script to generate iOS app icons from a source image

SOURCE_IMAGE="icons/Gemini_Mar13_v2_no_alpha.png"
OUTPUT_DIR="RealEstateMileageTracker/Assets.xcassets/AppIcon.appiconset"

# Check if source image exists
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "Error: Source image not found at $SOURCE_IMAGE"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Generating app icons from $SOURCE_IMAGE..."

# iOS App Icon sizes
# Format: filename:size
SIZES=(
    "AppIcon-1024.png:1024"
    "AppIcon-20@2x.png:40"
    "AppIcon-20@3x.png:60"
    "AppIcon-29@2x.png:58"
    "AppIcon-29@3x.png:87"
    "AppIcon-40@2x.png:80"
    "AppIcon-40@3x.png:120"
    "AppIcon-60@2x.png:120"
    "AppIcon-60@3x.png:180"
    "AppIcon-76.png:76"
    "AppIcon-76@2x.png:152"
    "AppIcon-83.5@2x.png:167"
)

# Generate each size
for entry in "${SIZES[@]}"
do
    IFS=':' read -r filename size <<< "$entry"
    output_path="$OUTPUT_DIR/$filename"
    echo "Generating $filename (${size}x${size})..."
    sips -z "$size" "$size" "$SOURCE_IMAGE" --out "$output_path" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        # Remove alpha channel (required by Apple)
        sips -s hasAlpha no "$output_path" > /dev/null 2>&1
        echo "✓ Created $filename (alpha channel removed)"
    else
        echo "✗ Failed to create $filename"
    fi
done

echo ""
echo "✅ App icon generation complete!"
echo "Icons saved to: $OUTPUT_DIR"
