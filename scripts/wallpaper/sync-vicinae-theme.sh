#!/usr/bin/env bash
set -eu

palette_file="${1:-$HOME/.local/state/wallpaper/wallust-palette.json}"
dark_theme_file="${2:-$HOME/.local/share/vicinae/themes/wallust-dark.toml}"
light_theme_file="${3:-$HOME/.local/share/vicinae/themes/wallust-light.toml}"

[ -r "$palette_file" ] || exit 0

if ! jq -e '.background and .foreground and .color0 and .color7 and .color8 and .color9 and .color10 and .color11 and .color12 and .color13 and .color14' "$palette_file" >/dev/null 2>&1; then
  exit 0
fi

background="$(jq -r '.background // empty' "$palette_file")"
foreground="$(jq -r '.foreground // empty' "$palette_file")"
color0="$(jq -r '.color0 // empty' "$palette_file")"
color7="$(jq -r '.color7 // empty' "$palette_file")"
color8="$(jq -r '.color8 // empty' "$palette_file")"
color9="$(jq -r '.color9 // empty' "$palette_file")"
color10="$(jq -r '.color10 // empty' "$palette_file")"
color11="$(jq -r '.color11 // empty' "$palette_file")"
color12="$(jq -r '.color12 // empty' "$palette_file")"
color13="$(jq -r '.color13 // empty' "$palette_file")"
color14="$(jq -r '.color14 // empty' "$palette_file")"

for color in "$background" "$foreground" "$color0" "$color7" "$color8" "$color9" "$color10" "$color11" "$color12" "$color13" "$color14"; do
  [ -n "$color" ] || exit 0
done

mkdir -p "$(dirname "$dark_theme_file")"
mkdir -p "$(dirname "$light_theme_file")"

tmp_dark="$dark_theme_file.tmp"
tmp_light="$light_theme_file.tmp"

cat > "$tmp_dark" <<EOF
[meta]
version = 1
name = "Wallust Dark"
description = "Wallust-generated dark theme"
variant = "dark"
inherits = "vicinae-dark"

[colors.core]
background = "$background"
foreground = "$foreground"
secondary_background = "$color0"
border = "$color8"
accent = "$color12"

[colors.accents]
blue = "$color12"
green = "$color10"
magenta = "$color13"
orange = "$color11"
purple = "$color13"
red = "$color9"
yellow = "$color11"
cyan = "$color14"

[colors.list.item.selection]
background = "$color0"
secondary_background = "$color8"
EOF

cat > "$tmp_light" <<EOF
[meta]
version = 1
name = "Wallust Light"
description = "Wallust-generated light theme"
variant = "light"
inherits = "vicinae-light"

[colors.core]
background = "$foreground"
foreground = "$background"
secondary_background = "$color7"
border = "$color8"
accent = "$color11"

[colors.accents]
blue = "$color12"
green = "$color10"
magenta = "$color13"
orange = "$color11"
purple = "$color13"
red = "$color9"
yellow = "$color11"
cyan = "$color14"

[colors.list.item.selection]
background = "$color7"
secondary_background = "$color8"
EOF

mv "$tmp_dark" "$dark_theme_file"
mv "$tmp_light" "$light_theme_file"
