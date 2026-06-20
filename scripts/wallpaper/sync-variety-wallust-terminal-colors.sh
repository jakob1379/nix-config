#!/usr/bin/env bash
set -eu

variety_bin="${1:-variety}"

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
  printf 'sync-variety-wallpaper-state: no readable wallpaper returned by %s --get after %s attempts\n' "$variety_bin" "$attempts" >&2
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
