#!/bin/bash
# Generates the macOS app icon set. Requires ImageMagick 7 (`magick`).
#
#   ./design/build_icons.sh
#
# The mark is a T built from two equal horizontal bars with a stem between
# them: the top bar is the full version, the bottom bar is the floor. They are
# drawn identically on purpose — in this app the floor counts exactly as much
# as the ceiling, and the icon should not quietly rank them.
#
# Three geometries are drawn, because the mark has to survive being small:
#   128px+   the full mark
#   32/64px  heavier and larger, since the fine version lands under two pixels
#   16px     the T alone — at sixteen pixels the gap under the stem is less
#            than one pixel, so the floor bar just smears into the letter
set -euo pipefail

cd "$(dirname "$0")/.."
out=macos/Runner/Assets.xcassets/AppIcon.appiconset
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mint='#9BEBCB'
top='#17251F'
bottom='#0A0D0C'

# --- large geometry: squircle 100..923, radius 185 -------------------------
magick -size 1024x1024 gradient:"$top-$bottom" "$work/grad.png"
magick -size 1024x1024 xc:black -fill white \
  -draw "roundrectangle 100,100 923,923 185,185" "$work/mask.png"
magick "$work/grad.png" "$work/mask.png" -alpha off \
  -compose CopyOpacity -composite png32:"$work/plate.png"

# The soft shadow Apple's icon template expects, baked into the artwork: a
# black silhouette of the plate, faded, blurred and dropped a few pixels.
magick -size 1024x1024 xc:black "$work/mask.png" -alpha off \
  -compose CopyOpacity -composite \
  -channel A -evaluate multiply 0.42 +channel \
  -blur 0x16 png32:"$work/shadow_blur.png"
magick -size 1024x1024 xc:none "$work/shadow_blur.png" \
  -geometry +0+14 -compose Over -composite png32:"$work/shadow.png"

magick "$work/shadow.png" "$work/plate.png" -compose Over -composite \
  -stroke '#FFFFFF22' -strokewidth 1.5 -fill none \
  -draw "roundrectangle 101,101 922,922 184,184" \
  -stroke none -fill "$mint" \
  -draw "roundrectangle 300,268 723,353 24,24" \
  -draw "roundrectangle 469,268 554,634 24,24" \
  -draw "roundrectangle 300,672 723,757 24,24" \
  png32:"$work/large.png"

# --- small geometry: squircle 60..963, radius 203, heavier strokes ---------
magick -size 1024x1024 xc:black -fill white \
  -draw "roundrectangle 60,60 963,963 203,203" "$work/mask_s.png"
magick -size 1024x1024 xc:'#111A16' "$work/mask_s.png" -alpha off \
  -compose CopyOpacity -composite \
  -stroke none -fill "$mint" \
  -draw "roundrectangle 230,187 794,317 30,30" \
  -draw "roundrectangle 447,187 577,657 30,30" \
  -draw "roundrectangle 230,707 794,837 30,30" \
  png32:"$work/small.png"

# --- tiny geometry: the T alone, as big as it will go ---------------------
magick -size 1024x1024 xc:'#111A16' "$work/mask_s.png" -alpha off \
  -compose CopyOpacity -composite \
  -stroke none -fill "$mint" \
  -draw "roundrectangle 200,250 824,410 36,36" \
  -draw "roundrectangle 432,250 592,790 36,36" \
  png32:"$work/tiny.png"

cp "$work/large.png" design/icon-1024.png

for size in 128 256 512 1024; do
  magick "$work/large.png" -filter Lanczos -resize "${size}x${size}" \
    "png32:$out/app_icon_$size.png"
done
for size in 32 64; do
  magick "$work/small.png" -filter Lanczos -resize "${size}x${size}" \
    "png32:$out/app_icon_$size.png"
done
magick "$work/tiny.png" -filter Lanczos -resize 16x16 "png32:$out/app_icon_16.png"

echo "wrote $out/app_icon_{16,32,64,128,256,512,1024}.png"
