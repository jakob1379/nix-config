# shellcheck shell=bash

session_wrapper_find_file() {
  local session_file_name="$1"
  local current_dir="${2:-$PWD}"
  local git_root

  if ! git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
    [[ -f "$current_dir/$session_file_name" ]] || return 1
    printf '%s\n' "$current_dir/$session_file_name"
    return 0
  fi

  while :; do
    if [[ -f "$current_dir/$session_file_name" ]]; then
      printf '%s\n' "$current_dir/$session_file_name"
      return 0
    fi

    if [[ "$current_dir" == "$git_root" || "$current_dir" == "/" ]]; then
      break
    fi

    current_dir=$(dirname "$current_dir")
  done

  return 1
}

session_wrapper_default_file() {
  local session_file_name="$1"
  local git_root

  if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
    printf '%s\n' "$git_root/$session_file_name"
  else
    printf './%s\n' "$session_file_name"
  fi
}

session_wrapper_save_id() {
  local session_id="$1"
  local session_file="$2"

  printf '%s\n' "$session_id" >"$session_file"
}

session_wrapper_load_id() {
  local session_file_name="$1"
  local session_file
  local session_id

  if ! session_file=$(session_wrapper_find_file "$session_file_name"); then
    return 1
  fi

  session_id=$(tr -d '[:space:]' <"$session_file")
  if [[ -z "$session_id" ]]; then
    rm -f "$session_file"
    return 1
  fi

  printf '%s\n' "$session_id"
}
