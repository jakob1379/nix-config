#!/usr/bin/env bash
set -eu

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
runtime_dir="$(mktemp -d)"
state_file="$runtime_dir/battery-screen-border"
systemctl_log="$runtime_dir/systemctl.log"
export SYSTEMCTL_LOG="$systemctl_log"
trap 'rm -rf "$runtime_dir"' EXIT

systemctl() {
  printf '%s\n' "$*" > "$SYSTEMCTL_LOG"
}
export -f systemctl

check_case() {
  local percent="$1"
  local state="$2"
  local expected_command="$3"
  local expected_border="${4:-}"
  local threshold="${5:-20}"

  rm -f "$state_file" "$systemctl_log"
  printf 'stale\n' > "$state_file"
  XDG_RUNTIME_DIR="$runtime_dir" \
    NOCTALIA_BATTERY_PERCENT="$percent" \
    NOCTALIA_BATTERY_STATE="$state" \
    bash "$script_dir/update-battery-border.sh" "$threshold"

  [ "$(< "$systemctl_log")" = "$expected_command" ]
  if [ -n "$expected_border" ]; then
    [ "$(< "$state_file")" = "$expected_border" ]
  else
    [ ! -e "$state_file" ]
  fi
}

check_case 21 discharging "--user stop battery-screen-border.service"
check_case 20 discharging "--user restart battery-screen-border.service" "3 #ffb000 #ffb000"
check_case 15 discharging "--user restart battery-screen-border.service" "3 #ff7520 #ff7520"
check_case 10 discharging "--user restart battery-screen-border.service" "3 #ff9500 #ff2d55"
check_case 74 discharging "--user restart battery-screen-border.service" "3 #ff9110 #ff9110" 100
check_case 12 charging "--user stop battery-screen-border.service"

if XDG_RUNTIME_DIR="$runtime_dir" bash "$script_dir/update-battery-border.sh" 11 2>/dev/null; then
  exit 1
fi

printf 'update-battery-border: ok\n'
