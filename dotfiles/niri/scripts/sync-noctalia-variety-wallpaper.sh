#!/usr/bin/env bash
set -eu

variety_pointer_file="${1:-$HOME/.config/variety/wallpaper/wallpaper.jpg.txt}"

if ! pgrep -x niri >/dev/null; then
  exit 0
fi

if [ ! -r "$variety_pointer_file" ]; then
  exit 0
fi

IFS= read -r wallpaper_path < "$variety_pointer_file" || true
if [ -z "${wallpaper_path:-}" ] || [ ! -r "$wallpaper_path" ]; then
  exit 0
fi

noctalia-shell ipc --newest call wallpaper set "$wallpaper_path" all >/dev/null 2>&1 || true
