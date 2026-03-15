#!/usr/bin/env bash
set -eu

palette_file="${1:-$HOME/.local/state/wallpaper/wallust-palette.json}"
noctalia_colors_file="${2:-$HOME/.config/noctalia/colors.json}"
target_file="${3:-$HOME/.config/niri/generated/wallust-focus-ring.kdl}"

from_color=""
to_color=""

if [ -r "$palette_file" ] && jq -e '.color12 and .color10' "$palette_file" >/dev/null 2>&1; then
  from_color="$(jq -r '.color12 // empty' "$palette_file")"
  to_color="$(jq -r '.color10 // empty' "$palette_file")"
fi

if [ -z "$from_color" ] || [ -z "$to_color" ]; then
  if [ -r "$noctalia_colors_file" ]; then
    from_color="$(jq -r '.mPrimary // empty' "$noctalia_colors_file")"
    to_color="$(jq -r '.mHover // empty' "$noctalia_colors_file")"
  fi
fi

[ -n "$from_color" ] || exit 0
[ -n "$to_color" ] || exit 0

mkdir -p "$(dirname "$target_file")"
tmp_file="$target_file.tmp"
printf '%s\n' \
  'layout {' \
  '    focus-ring {' \
  "        active-gradient from=\"$from_color\" to=\"$to_color\" angle=45" \
  '    }' \
  '}' > "$tmp_file"
mv "$tmp_file" "$target_file"

if pgrep -x niri >/dev/null 2>&1; then
  niri msg action load-config-file >/dev/null 2>&1 || true
fi
