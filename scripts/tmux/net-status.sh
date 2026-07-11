#!/usr/bin/env bash

set -u

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
state_dir="$runtime_dir/tmux-net-status-$UID"
timeout="${TMUX_NET_TIMEOUT:-1}"
client_host="${TMUX_NET_CLIENT_HOST:-}"
client_port="${TMUX_NET_CLIENT_PORT:-22}"
client_source_port=""
ssh_server_port=""
success_ttl=30
failure_ttl=10

mkdir -p "$state_dir"

tmux_option() {
  if [ -n "${TMUX:-}" ]; then
    tmux show-option -gqv "$1" 2>/dev/null || true
  fi
}

tmux_environment() {
  local value

  if [ -n "${TMUX:-}" ]; then
    value="$(tmux show-environment "$1" 2>/dev/null || tmux show-environment -g "$1" 2>/dev/null || true)"
    case "$value" in
      "$1="*) printf '%s\n' "${value#*=}" ;;
    esac
  fi
}

resolve_ssh_client() {
  local value

  value="$(tmux_environment SSH_CLIENT)"
  if [ -z "$value" ]; then
    value="${SSH_CLIENT:-}"
  fi
  if [ -n "$value" ]; then
    read -r client_host client_source_port ssh_server_port _ <<EOF
$value
EOF
    return
  fi

  value="$(tmux_environment SSH_CONNECTION)"
  if [ -z "$value" ]; then
    value="${SSH_CONNECTION:-}"
  fi
  if [ -n "$value" ]; then
    read -r client_host client_source_port _ ssh_server_port _ <<EOF
$value
EOF
  fi
}

resolve_ssh_client
option_value="$(tmux_option @tmux-net-client-host)"
[ -z "$client_host" ] && [ -n "$option_value" ] && client_host="$option_value"
option_value="$(tmux_option @tmux-net-client-source-port)"
[ -z "$client_source_port" ] && [ -n "$option_value" ] && client_source_port="$option_value"
option_value="$(tmux_option @tmux-net-ssh-server-port)"
[ -z "$ssh_server_port" ] && [ -n "$option_value" ] && ssh_server_port="$option_value"
option_value="$(tmux_option @tmux-net-client-port)"
[ -z "$ssh_server_port" ] && [ -n "$option_value" ] && ssh_server_port="$option_value"
[ -n "$ssh_server_port" ] && client_port="$ssh_server_port"
option_value="$(tmux_option @tmux-net-timeout)"
[ -n "$option_value" ] && timeout="$option_value"

if [ -z "$client_host" ]; then
  exit 0
fi

cache_key="$(printf '%s-%s\n' "${client_host:-none}" "$client_port" | tr -c 'A-Za-z0-9_.-' '_')"
cache="$state_dir/status-$cache_key"
lock="$state_dir/lock-$cache_key"

format_latency_ms() {
  local latency="$1"

  latency="${latency%%.*}"
  printf '%sms\n' "$latency"
}

ssh_connection_latency() {
  local output
  local latency

  if [ -z "$client_source_port" ]; then
    return 1
  fi
  if [ -z "$ssh_server_port" ]; then
    ssh_server_port="$client_port"
  fi

  output="$(ss -tin state established "( sport = :$ssh_server_port and dport = :$client_source_port )" 2>/dev/null)" || return 1
  latency="${output#*rtt:}"
  if [ "$latency" = "$output" ]; then
    return 1
  fi

  latency="${latency%%/*}"
  format_latency_ms "$latency"
}

ping_latency() {
  local output
  local latency

  output="$(ping -n -c 1 -W "$timeout" "$1" 2>/dev/null)" || return 1
  latency="${output#*time=}"
  if [ "$latency" = "$output" ]; then
    return 1
  fi

  latency="${latency%% *}"
  format_latency_ms "$latency"
}

render() {
  local client_status="?"
  local client_latency
  local ttl="$failure_ttl"
  local now
  now="$(date +%s)"

  if [ -n "$client_host" ]; then
    client_status="down"
    if client_latency="$(ssh_connection_latency)"; then
      client_status="$client_latency"
      ttl="$success_ttl"
    elif client_latency="$(ping_latency "$client_host")"; then
      client_status="$client_latency"
      ttl="$success_ttl"
    fi
  fi

  printf '%s\t%s\tSSH: %s\n' "$now" "$ttl" "$client_status" > "$cache.tmp"
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
  printf '%s\n' "${cache_text:-SSH: ?}"
  exit 0
fi

refresh_background
printf 'SSH: ?\n'
