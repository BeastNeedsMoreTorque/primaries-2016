#!/bin/sh

DIR="$(dirname "$0")"
IN_DIR="$DIR/horses"
OUT_DIR="$DIR/../assets/images/horses"

for path in $(ls "$IN_DIR"/*-horse.png "$IN_DIR"/*-horse-win.png); do
  basename="$(basename "$path")"

  # http://www.imagemagick.org/Usage/advanced/#3d-logos
  #
  # 1. Shade it in, to add a 3D effect.
  # 2. Add a drop-shadow blur.

  set -x
  convert \
    "$path" -alpha extract -blur 0x5 -shade 90x40 -normalize \
    "$path" -compose Overlay -composite \
    "$path" -alpha on -compose Dst_In -composite \
    \( +clone -channel A -blur 5x5 -level 0,85% +channel +level-colors black \) \
    -compose DstOver -composite \
    -define png:include-chunk=none \
    "$OUT_DIR/$basename"
  set +x
done

for path in $(ls "$IN_DIR"/*-target.png); do
  basename="$(basename "$path")"

  # http://www.imagemagick.org/Usage/advanced/#3d-logos
  #
  # 1. Shade it in, to add a 3D effect.
  # 2. Add a drop-shadow blur.

  set -x
  convert \
    "$path" -alpha extract -blur 0x7 -shade 90x40 -normalize \
    "$path" -compose Overlay -composite \
    "$path" -alpha on -compose Dst_In -composite \
    \( +clone -channel A -blur 3x3 -level 0,90% +channel +level-colors black \) \
    -compose DstOver -composite \
    -define png:include-chunk=none \
    "$OUT_DIR/$basename"
  set +x
done
