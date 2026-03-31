#!/usr/bin/env bash

set -euo pipefail

main() {
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nix"
  local config_file="$config_dir/nix.conf"

  if ! command -v nix >/dev/null 2>&1; then
    printf 'Installing nix\n'
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  else
    printf 'Nix is already installed.\n'
  fi

  printf 'Ensuring Nix is configured for flakes...\n'
  mkdir -p "$config_dir"
  touch "$config_file"

  if ! grep -Eq '^[[:space:]]*experimental-features[[:space:]]*=' "$config_file"; then
    printf 'Appending experimental-features to %s...\n' "$config_file"
    printf 'experimental-features = nix-command flakes\n' >> "$config_file"
  else
    printf 'Nix experimental features already configured in %s.\n' "$config_file"
  fi
}

main "$@"
