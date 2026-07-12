#!/usr/bin/env bash
set -eu

override_file="$HOME/.local/state/niri/battery-border.kdl"

read_battery() {
  local battery=""

  if [[ "${NOCTALIA_BATTERY_PERCENT:-}" =~ ^[0-9]+$ ]]; then
    percent="$NOCTALIA_BATTERY_PERCENT"
    battery_state="${NOCTALIA_BATTERY_STATE:-unknown}"
    return
  fi

  for battery in /sys/class/power_supply/BAT*; do
    [ -d "$battery" ] || continue
    IFS= read -r percent < "$battery/capacity"
    IFS= read -r battery_state < "$battery/status"
    return
  done

  percent=""
  battery_state="unknown"
}

write_override() {
  local directory="${override_file%/*}"
  local temporary=""

  mkdir -p "$directory"
  temporary="$(mktemp "$override_file.XXXXXX")"
  trap 'rm -f "$temporary"' EXIT
  cat > "$temporary"
  mv "$temporary" "$override_file"
  trap - EXIT
}

render_alarm() {
  local progress=$((20 - percent))
  local active_green=$((176 - (107 * progress / 9)))
  local active_blue=$((0 + (58 * progress / 9)))
  local inactive_red=$((107 + (15 * progress / 9)))
  local inactive_green=$((75 - (44 * progress / 9)))
  local inactive_blue=$((0 + (26 * progress / 9)))
  local active=""
  local inactive=""

  printf -v active '#ff%02x%02x' "$active_green" "$active_blue"
  printf -v inactive '#%02x%02x%02x' "$inactive_red" "$inactive_green" "$inactive_blue"

  cat <<EOF
layout {
    border {
        active-color "$active"
        inactive-color "$inactive"
    }
}
EOF
}

read_battery
battery_state="${battery_state,,}"
battery_state="${battery_state// /_}"

if ! [[ "$percent" =~ ^[0-9]+$ ]] || [ "$percent" -gt 20 ] || [[ "$battery_state" != "discharging" && "$battery_state" != "pending_discharge" ]]; then
  printf '// Low-battery border inactive.\n' | write_override
elif [ "$percent" -le 10 ]; then
  cat <<'EOF' | write_override
layout {
    border {
        active-gradient from="#ff9500" to="#ff2d55" angle=90 relative-to="workspace-view"
        inactive-gradient from="#7a1f1a" to="#4a0b12" angle=90 relative-to="workspace-view"
    }
}
EOF
else
  render_alarm | write_override
fi
