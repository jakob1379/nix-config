#!/usr/bin/env bash
set -eu

if ! pgrep -x niri >/dev/null; then
  exit 0
fi

wallpaper_path=$(variety --get) || true
if [ -z "${wallpaper_path:-}" ] || [ ! -r "$wallpaper_path" ]; then
  exit 0
fi

noctalia-shell ipc --newest call wallpaper set "$wallpaper_path" all >/dev/null 2>&1 || true
