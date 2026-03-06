#!/usr/bin/env bash
set -eu

wallust_cache_dir="${1:-$HOME/.cache/wallust}"
noctalia_colors_file="${2:-$HOME/.config/noctalia/colors.json}"
target_file="${3:-$HOME/.config/niri/generated/wallust-focus-ring.kdl}"

from_color=""
to_color=""
latest_dir=""

if [ -d "$wallust_cache_dir" ]; then
  for dir in "$wallust_cache_dir"/*_1.7; do
    [ -d "$dir" ] || continue
    if [ -z "$latest_dir" ] || [ "$dir" -nt "$latest_dir" ]; then
      latest_dir="$dir"
    fi
  done

  if [ -n "$latest_dir" ]; then
    for candidate in "$latest_dir"/*; do
      [ -f "$candidate" ] || continue
      if jq -e '.color12 and .color10' "$candidate" >/dev/null 2>&1; then
        from_color="$(jq -r '.color12 // empty' "$candidate")"
        to_color="$(jq -r '.color10 // empty' "$candidate")"
        break
      fi
    done
  fi
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
