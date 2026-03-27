#!/usr/bin/env bash
set -eu

wallpaper_state_file="${1:-$HOME/.local/state/wallpaper/current-wallpaper}"

if ! pgrep -x niri >/dev/null; then
  exit 0
fi

if [ ! -r "$wallpaper_state_file" ]; then
  exit 0
fi

IFS= read -r wallpaper_path < "$wallpaper_state_file" || true
if [ -z "${wallpaper_path:-}" ] || [ ! -r "$wallpaper_path" ]; then
  exit 0
fi

if ! output="$(noctalia-shell ipc --newest call wallpaper set "$wallpaper_path" all 2>&1)"; then
  printf 'sync-noctalia-wallpaper: failed to set wallpaper to %s: %s\n' "$wallpaper_path" "$output" >&2
fi
