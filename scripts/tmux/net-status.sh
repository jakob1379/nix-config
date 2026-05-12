#!/usr/bin/env bash

set -u

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
state_dir="$runtime_dir/tmux-net-status-$UID"
cache="$state_dir/status"
lock="$state_dir/lock"
timeout="${TMUX_NET_TIMEOUT:-1}"
public_host="${TMUX_NET_PUBLIC_HOST:-1.1.1.1}"
public_port="${TMUX_NET_PUBLIC_PORT:-443}"
client_host="${TMUX_NET_CLIENT_HOST:-}"
client_port="${TMUX_NET_CLIENT_PORT:-22}"
success_ttl=30
failure_ttl=10

mkdir -p "$state_dir"

tmux_option() {
  if [ -n "${TMUX:-}" ]; then
    tmux show-option -gqv "$1" 2>/dev/null || true
  fi
}

option_value="$(tmux_option @tmux-net-public-host)"
[ -n "$option_value" ] && public_host="$option_value"
option_value="$(tmux_option @tmux-net-public-port)"
[ -n "$option_value" ] && public_port="$option_value"
option_value="$(tmux_option @tmux-net-client-host)"
[ -n "$option_value" ] && client_host="$option_value"
option_value="$(tmux_option @tmux-net-client-port)"
[ -n "$option_value" ] && client_port="$option_value"
option_value="$(tmux_option @tmux-net-timeout)"
[ -n "$option_value" ] && timeout="$option_value"

check_tcp() {
  toybox nc -z -w "$timeout" "$1" "$2" >/dev/null 2>&1
}

render() {
  local net_status="down"
  local client_status="-"
  local ttl="$failure_ttl"
  local now
  now="$(date +%s)"

  if check_tcp "$public_host" "$public_port"; then
    net_status="up"
    ttl="$success_ttl"
  fi

  if [ -n "$client_host" ]; then
    client_status="down"
    if check_tcp "$client_host" "$client_port"; then
      client_status="up"
    fi

    printf '%s\t%s\tSSH: %s Net: %s\n' "$now" "$ttl" "$client_status" "$net_status" > "$cache.tmp"
  else
    printf '%s\t%s\tNet: %s\n' "$now" "$ttl" "$net_status" > "$cache.tmp"
  fi

  mv "$cache.tmp" "$cache"
}

refresh_background() {
  if mkdir "$lock" 2>/dev/null; then
    (trap 'rmdir "$lock"' EXIT; render) >/dev/null 2>&1 &
  fi
}

if [ "${1:-}" = "--refresh" ]; then
  render
fi

now="$(date +%s)"
if [ -r "$cache" ]; then
  IFS=$'\t' read -r cache_time cache_ttl cache_text < "$cache" || true
  if [ -n "${cache_time:-}" ] && [ -n "${cache_ttl:-}" ] && [ "$((now - cache_time))" -lt "$cache_ttl" ]; then
    printf '%s\n' "$cache_text"
    exit 0
  fi

  refresh_background
  printf '%s\n' "${cache_text:-Net: ?}"
  exit 0
fi

refresh_background
printf 'Net: ?\n'
