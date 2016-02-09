#!/bin/sh

DIR="$(dirname "$0")"
IN_DIR="$DIR/headshots"
OUT_DIR="$DIR/../assets/images/big-headshots"

mkdir -pv "$OUT_DIR"
cp -v "$IN_DIR"/*.png "$OUT_DIR"
