#!/usr/bin/env bash

set -eu

current_wallpaper_state_file="$1"
wallust_cache_dir="$2"
wallust_palette_state_file="$3"

if [ ! -r "$current_wallpaper_state_file" ]; then
  exit 0
fi

IFS= read -r wallpaper_path < "$current_wallpaper_state_file" || exit 0
if [ -z "$wallpaper_path" ] || [ ! -r "$wallpaper_path" ]; then
  exit 0
fi

wallust run -k "$wallpaper_path"
update-wallust-palette-state "$wallust_cache_dir" "$wallust_palette_state_file"
