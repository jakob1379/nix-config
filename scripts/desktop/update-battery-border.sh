#!/usr/bin/env bash
set -eu

state_file="${XDG_RUNTIME_DIR:?}/battery-screen-border"
service_name="battery-screen-border.service"
warning_threshold="${1:-}"

if ! [[ "$warning_threshold" =~ ^[0-9]+$ ]] || [ "$warning_threshold" -lt 12 ] || [ "$warning_threshold" -gt 100 ]; then
  printf 'warning threshold must be an integer between 12 and 100\n' >&2
  exit 2
fi
warning_threshold=$((10#$warning_threshold))

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

write_state() {
  local temporary=""

  temporary="$(mktemp "$state_file.XXXXXX")"
  trap 'rm -f "$temporary"' EXIT
  cat > "$temporary"
  mv "$temporary" "$state_file"
  trap - EXIT
}

render_color() {
  local progress=$((warning_threshold - percent))
  local range=$((warning_threshold - 11))
  local green=$((176 - (107 * progress / range)))
  local blue=$((58 * progress / range))

  printf '#ff%02x%02x' "$green" "$blue"
}

read_battery
battery_state="${battery_state,,}"
battery_state="${battery_state// /_}"
if [[ "$percent" =~ ^[0-9]+$ ]]; then
  percent=$((10#$percent))
fi

if ! [[ "$percent" =~ ^[0-9]+$ ]] || [ "$percent" -gt "$warning_threshold" ] || [[ "$battery_state" != "discharging" && "$battery_state" != "pending_discharge" ]]; then
  rm -f "$state_file"
  systemctl --user stop "$service_name" || true
elif [ "$percent" -le 10 ]; then
  printf '3 #ff9500 #ff2d55\n' | write_state
  systemctl --user restart "$service_name"
else
  color="$(render_color)"
  printf '3 %s %s\n' "$color" "$color" | write_state
  systemctl --user restart "$service_name"
fi
