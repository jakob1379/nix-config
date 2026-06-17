#!/usr/bin/env bash
set -eu

variety_bin="${1:-variety}"
current_wallpaper_state_file="${2:-$HOME/.local/state/wallpaper/current-wallpaper}"

attempts=0
wallpaper_path=""

while [ "$attempts" -lt 30 ]; do
  if wallpaper_path="$("$variety_bin" --get 2>/dev/null)"; then
    :
  else
    wallpaper_path=""
  fi

  if [ -n "$wallpaper_path" ] && [ -r "$wallpaper_path" ]; then
    break
  fi

  attempts=$((attempts + 1))
  sleep 1
done

if [ -z "$wallpaper_path" ] || [ ! -r "$wallpaper_path" ]; then
  printf 'sync-variety-wallpaper-theme: no readable wallpaper returned by %s --get after %s attempts\n' "$variety_bin" "$attempts" >&2
  exit 1
fi

mkdir -p "$(dirname "$current_wallpaper_state_file")"
current_wallpaper_tmp="$current_wallpaper_state_file.tmp"
printf '%s\n' "$wallpaper_path" > "$current_wallpaper_tmp"
mv "$current_wallpaper_tmp" "$current_wallpaper_state_file"

sync-noctalia-wallpaper "$current_wallpaper_state_file"

if ! output="$(timeout --kill-after=5s 20s wallust run --overwrite-cache -k "$wallpaper_path" 2>&1)"; then
  printf 'sync-variety-wallpaper-theme: wallust did not finish cleanly for %s: %s\n' "$wallpaper_path" "$output" >&2
fi
