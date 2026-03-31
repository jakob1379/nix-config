#!/usr/bin/env bash

set -eu

pointer_file="$1"
target_file="$2"
attempts=0

sleep 3

while [ "$attempts" -lt 5 ]; do
  wallpaper_path=""

  if [ -r "$pointer_file" ]; then
    wallpaper_path="$(< "$pointer_file")"
  fi

  if [ -n "${wallpaper_path:-}" ] && [ -r "$wallpaper_path" ]; then
    current_wallpaper=""

    if [ -r "$target_file" ]; then
      current_wallpaper="$(< "$target_file")"
    fi

    if [ "$current_wallpaper" = "$wallpaper_path" ]; then
      exit 0
    fi

    mkdir -p "$(dirname "$target_file")"
    tmp_file="$target_file.tmp"
    printf '%s\n' "$wallpaper_path" > "$tmp_file"
    mv "$tmp_file" "$target_file"
    exit 0
  fi

  attempts=$((attempts + 1))
  sleep 1
done

exit 1
