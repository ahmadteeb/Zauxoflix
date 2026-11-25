#!/usr/bin/env bash
set -euo pipefail

source_dir="$(dirname "$(realpath "$0")")"
target="$1"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/zauxoflix/seek-frames"
headers="$cache/ffmpeg-6.1.6"
archive="$headers.tar.xz"
checksum=d4fcb164028dd3beee5d92c0ac72e46aac6973c75ea12dc14de07bf8f407370a
mkdir -p "$cache" "$(dirname "$target")"
if [[ ! -f "$headers/libavutil/avconfig.h" ]]; then
  if [[ ! -f "$archive" ]]; then
    curl --fail --silent --show-error --location --max-time 60 \
      https://ffmpeg.org/releases/ffmpeg-6.1.6.tar.xz -o "$archive.part"
    printf '%s  %s\n' "$checksum" "$archive.part" | sha256sum --check --status
    mv "$archive.part" "$archive"
  fi
  printf '%s  %s\n' "$checksum" "$archive" | sha256sum --check --status
  tar -xJf "$archive" -C "$cache"
  printf '#define AV_HAVE_BIGENDIAN 0\n#define AV_HAVE_FAST_UNALIGNED 0\n' \
    > "$headers/libavutil/avconfig.h"
fi

# The LG SDK sets CC to the compiler and its target/sysroot options.
read -r -a compiler <<< "${CC:-cc}"
flags=(-fPIC -c)
if [[ "$target" != *.o ]]; then
  flags=(-DSEEK_FRAMES_STANDALONE -ldl)
fi
"${compiler[@]}" -std=c11 -O2 -Wall -Wextra -Werror -I"$headers" \
  "$source_dir/seek-frames.c" "${flags[@]}" -o "$target"
