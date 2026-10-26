#!/usr/bin/env bash
set -eu

variety_bin="${1:-variety}"
wallpaper_pointer_file="${2:-}"

attempts=0
wallpaper_path=""

read_pointer_wallpaper() {
  local pointer_file="$1"
  local path=""

  if [ -n "$pointer_file" ] && [ -r "$pointer_file" ]; then
    IFS= read -r path < "$pointer_file" || true
  fi

  printf '%s' "$path"
}

while [ "$attempts" -lt 30 ]; do
  wallpaper_path="$(read_pointer_wallpaper "$wallpaper_pointer_file")"

  if [ -z "$wallpaper_path" ]; then
    if wallpaper_path="$("$variety_bin" --get 2>/dev/null)"; then
      :
    else
      wallpaper_path=""
    fi
  fi

  if [ -n "$wallpaper_path" ] && [ -r "$wallpaper_path" ]; then
    break
  fi

  attempts=$((attempts + 1))
  sleep 1
done

if [ -z "$wallpaper_path" ] || [ ! -r "$wallpaper_path" ]; then
  printf 'sync-variety-wallpaper-state: no readable wallpaper found from %s or %s --get after %s attempts\n' "${wallpaper_pointer_file:-<no pointer file>}" "$variety_bin" "$attempts" >&2
  exit 1
fi

noctalia_attempts=0
noctalia_output=""

while [ "$noctalia_attempts" -lt 15 ]; do
  if noctalia_output="$(timeout --kill-after=5s 20s noctalia msg wallpaper-set "$wallpaper_path" 2>&1)"; then
    break
  fi

  noctalia_attempts=$((noctalia_attempts + 1))
  sleep 1
done

if [ "$noctalia_attempts" -ge 15 ]; then
  printf 'sync-variety-wallpaper-state: noctalia did not accept wallpaper %s: %s\n' "$wallpaper_path" "$noctalia_output" >&2
  exit 1
fi

if ! output="$(timeout --kill-after=5s 20s wallust run --overwrite-cache -k "$wallpaper_path" 2>&1)"; then
  printf 'sync-variety-wallpaper-state: wallust did not finish cleanly for %s: %s\n' "$wallpaper_path" "$output" >&2
  exit 1
fi
