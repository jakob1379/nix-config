#!/usr/bin/env bash

set -euo pipefail

# SSH ProxyCommand preflight that waits for KeePassXC-backed keys to reach the
# active SSH agent, then hands the TCP connection to netcat.

# Validate dependencies exist.
for cmd in keepassxc nc ssh-add; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Error: $cmd not found in PATH" >&2
    exit 1
  fi
done

# Validate arguments.
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <host> <port>" >&2
  exit 1
fi

MAX_RETRIES=${MAX_RETRIES:-30}
RETRY_COUNT=0
KEEPASSXC_LAUNCHED=false
WAIT_MESSAGE_SHOWN=false

launch_keepassxc() {
  # Launch KeePassXC once and let the retry loop wait for it to unlock and
  # populate the agent.
  if [[ "$KEEPASSXC_LAUNCHED" == true ]]; then
    return
  fi

  echo "SSH agent has no identities. Launching KeePassXC..." >&2
  keepassxc >/dev/null 2>&1 < /dev/null &
  KEEPASSXC_LAUNCHED=true
}

while true; do
  if ssh-add -l &> /dev/null; then
    status=0
  else
    status=$?
  fi

  # ssh-add -l returns 0 when keys are available, 1 when the agent is reachable
  # but empty, and 2 when the agent cannot be contacted.
  if [[ $status -eq 0 ]]; then
    break
  fi

  case "$status" in
    1)
      launch_keepassxc

      if [[ "$WAIT_MESSAGE_SHOWN" == false ]]; then
        echo "Waiting for KeePassXC to unlock and load SSH keys..." >&2
        WAIT_MESSAGE_SHOWN=true
      fi
      ;;
    2)
      echo "Error: Unable to contact SSH agent. Check SSH_AUTH_SOCK." >&2
      exit 1
      ;;
    *)
      echo "Error: ssh-add -l failed with status ${status}" >&2
      exit 1
      ;;
  esac

  if [[ $RETRY_COUNT -ge $MAX_RETRIES ]]; then
    echo "Error: Timed out waiting for KeePassXC to load SSH keys after ${MAX_RETRIES} attempts" >&2
    exit 1
  fi

  RETRY_COUNT=$((RETRY_COUNT + 1))
  sleep 1
done

exec nc "$1" "$2"
