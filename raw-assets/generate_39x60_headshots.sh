#!/bin/sh

DIR="$(dirname "$0")"
IN_DIR="$DIR/headshots"
OUT_DIR="$DIR/../assets/images"

for path in $(ls $IN_DIR/*.png); do
  basename="$(basename "$path")"

  # Headshots start at 100x155px.
  #
  # Steps:
  #
  # 1. Add a 5px border, making it 110x165px. (This is so we can add a blur)
  # 2. Add a white outline, with a blur.
  # 3. Resize to 48x72px.

  set -x
  convert "$IN_DIR/$basename" \
    -bordercolor transparent -border 5 \
    \( +clone -channel A -blur 7x7 -level 0,10% +channel +level-colors white \) \
    -compose DstOver -composite \
    -thumbnail 48x72 \
    -define png:include-chunk=none \
    "$OUT_DIR/$basename"
  set +x
done
