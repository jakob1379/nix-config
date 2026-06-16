#!/usr/bin/env bash
set -eu

variety_pointer_file="$1"
current_wallpaper_state_file="$2"
wallust_cache_dir="$3"
wallust_palette_state_file="$4"
noctalia_colors_file="$5"
niri_focus_gradient_file="$6"
vicinae_dark_theme_file="$7"
vicinae_light_theme_file="$8"

attempts=0
wallpaper_path=""

while [ "$attempts" -lt 30 ]; do
  if [ -r "$variety_pointer_file" ]; then
    wallpaper_path="$(< "$variety_pointer_file")"
  fi

  if [ -n "$wallpaper_path" ] && [ -r "$wallpaper_path" ]; then
    break
  fi

  attempts=$((attempts + 1))
  sleep 1
done

if [ -z "$wallpaper_path" ] || [ ! -r "$wallpaper_path" ]; then
  printf 'sync-variety-wallpaper-theme: no readable wallpaper found from %s after %s attempts\n' "$variety_pointer_file" "$attempts" >&2
  exit 1
fi

mkdir -p "$(dirname "$current_wallpaper_state_file")"
current_wallpaper_tmp="$current_wallpaper_state_file.tmp"
printf '%s\n' "$wallpaper_path" > "$current_wallpaper_tmp"
mv "$current_wallpaper_tmp" "$current_wallpaper_state_file"

run_marker="$(mktemp)"
trap 'rm -f "$run_marker"' EXIT
touch "$run_marker"

timeout --kill-after=5s 30s wallust run --skip-sequences --overwrite-cache -k "$wallpaper_path"
update-wallust-palette-state "$wallust_cache_dir" "$wallust_palette_state_file" "$run_marker"
sync-noctalia-wallpaper "$current_wallpaper_state_file"
sync-niri-focus-gradient "$wallust_palette_state_file" "$noctalia_colors_file" "$niri_focus_gradient_file"
sync-vicinae-theme "$wallust_palette_state_file" "$vicinae_dark_theme_file" "$vicinae_light_theme_file"
