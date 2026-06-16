#!/usr/bin/env bash

set -eu

wallust_cache_dir="$1"
target_file="$2"
run_marker="${3:-}"
palette_file=""

if [ -d "$wallust_cache_dir" ]; then
  for dir in "$wallust_cache_dir"/*_1.7; do
    [ -d "$dir" ] || continue
    for candidate in "$dir"/*; do
      [ -f "$candidate" ] || continue
      if [ -n "$run_marker" ] && [ -r "$run_marker" ] && [ ! "$candidate" -nt "$run_marker" ]; then
        continue
      fi
      if ! jq -e '.background and .foreground and .color0 and .color7 and .color8 and .color9 and .color10 and .color11 and .color12 and .color13 and .color14' "$candidate" >/dev/null 2>&1; then
        continue
      fi
      if [ -z "$palette_file" ] || [ "$candidate" -nt "$palette_file" ]; then
        palette_file="$candidate"
      fi
    done
  done
fi

[ -n "$palette_file" ] || exit 1

mkdir -p "$(dirname "$target_file")"
tmp_file="$target_file.tmp"
cp "$palette_file" "$tmp_file"
mv "$tmp_file" "$target_file"
