#!/usr/bin/env bash
set -eu

reload_config=1
target_file="$HOME/.config/niri/generated/window-border-rules.kdl"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-reload)
      reload_config=0
      ;;
    --target)
      shift
      target_file="$1"
      ;;
    *)
      target_file="$1"
      ;;
  esac
  shift
done

tmp_file="$target_file.tmp.$$"

windows_json="$(niri msg --json windows 2>/dev/null)" || exit 0

mkdir -p "$(dirname "$target_file")"

WINDOWS_JSON="$windows_json" python3 - > "$tmp_file" <<'PY'
import colorsys
import hashlib
import json
import os
import re


def to_hex(hue, saturation, lightness):
    red, green, blue = colorsys.hls_to_rgb(hue, lightness, saturation)
    return "#{:02x}{:02x}{:02x}".format(
        round(red * 255),
        round(green * 255),
        round(blue * 255),
    )


def title_colors(title):
    digest = hashlib.sha256(title.encode("utf-8")).digest()
    hue = int.from_bytes(digest[:2], "big") / 65535
    active = to_hex(hue, 0.72, 0.56)
    inactive = to_hex(hue, 0.42, 0.36)
    return active, inactive


def regex_escape_title(title):
    return re.sub(r"([.^$*+?{}\[\]\\|()])", r"\\\1", title)


windows = json.loads(os.environ.get("WINDOWS_JSON", "[]"))
titles = sorted(
    {
        window.get("title")
        for window in windows
        if isinstance(window.get("title"), str) and window.get("title") != ""
    }
)

for title in titles:
    regex = "^" + regex_escape_title(title) + "$"
    active_color, inactive_color = title_colors(title)
    print("window-rule {")
    print(f"    match title={json.dumps(regex, ensure_ascii=False)}")
    print("    border {")
    print(f"        active-color {json.dumps(active_color)}")
    print(f"        inactive-color {json.dumps(inactive_color)}")
    print("    }")
    print("}")
PY

if [ -f "$target_file" ] && cmp -s "$tmp_file" "$target_file"; then
  rm -f "$tmp_file"
  exit 0
fi

mv "$tmp_file" "$target_file"

if [ "$reload_config" -eq 1 ] && pgrep -x niri >/dev/null 2>&1; then
  niri msg action load-config-file >/dev/null 2>&1 || true
  printf '%s\n' reloaded
  exit 0
fi

printf '%s\n' updated
