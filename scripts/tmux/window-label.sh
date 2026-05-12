#!/usr/bin/env bash

set -u

path="${1:-$PWD}"
command="${2:-}"
max_length="${TMUX_WINDOW_LABEL_MAX_LENGTH:-32}"

shorten() {
  local value="$1"
  local limit="$2"

  if [ "${#value}" -le "$limit" ]; then
    printf '%s\n' "$value"
  else
    printf '%s…\n' "${value:0:$((limit - 1))}"
  fi
}

is_shell() {
  case "$1" in
    bash | dash | fish | sh | zsh)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

path_label() {
  local root
  local repo
  local relative
  local branch
  local label

  if root="$(git -C "$path" rev-parse --show-toplevel 2>/dev/null)"; then
    repo="$(basename "$root")"
    relative="$(realpath --relative-to="$root" "$path" 2>/dev/null || printf '.')"
    branch="$(git -C "$path" branch --show-current 2>/dev/null || true)"

    if [ -z "$branch" ]; then
      branch="$(git -C "$path" rev-parse --short HEAD 2>/dev/null || true)"
    fi

    label="$repo"

    if [ "$relative" != "." ]; then
      label="$label:$(basename "$relative")"
    fi

    if [ -n "$branch" ]; then
      label="$label $branch"
    fi

    printf '%s\n' "$label"
    return
  fi

  if [ "$path" = "$HOME" ]; then
    printf '~\n'
  else
    basename "$path"
  fi
}

label="$(path_label)"

if [ -n "$command" ] && ! is_shell "$command"; then
  label="$label $command"
fi

shorten "$label" "$max_length"
