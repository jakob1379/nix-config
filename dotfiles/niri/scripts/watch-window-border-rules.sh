#!/usr/bin/env bash
set -eu

sync_script="${1:-sync-niri-window-border-rules}"
target_file="${2:-$HOME/.config/niri/generated/window-border-rules.kdl}"
suppress_next_config_loaded=0

clear_rules() {
  mkdir -p "$(dirname "$target_file")"
  : > "$target_file"
}

clear_rules
"$sync_script" --no-reload --target "$target_file" >/dev/null
if pgrep -x niri >/dev/null 2>&1; then
  suppress_next_config_loaded=1
  niri msg action load-config-file >/dev/null 2>&1 || true
fi

niri msg --json event-stream | while IFS= read -r event_line; do
  [ -n "$event_line" ] || continue
  if printf '%s\n' "$event_line" | jq -e 'has("WindowsChanged")' >/dev/null 2>&1; then
    sync_result="$("$sync_script" --target "$target_file" 2>/dev/null || true)"
    if [ "$sync_result" = "reloaded" ]; then
      suppress_next_config_loaded=1
    fi
  elif printf '%s\n' "$event_line" | jq -e 'has("ConfigLoaded")' >/dev/null 2>&1; then
    if [ "$suppress_next_config_loaded" -eq 1 ]; then
      suppress_next_config_loaded=0
      continue
    fi

    clear_rules
    "$sync_script" --no-reload --target "$target_file" >/dev/null
    suppress_next_config_loaded=1
    niri msg action load-config-file >/dev/null 2>&1 || true
  fi
done
