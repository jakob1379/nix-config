# shellcheck shell=bash

session_wrapper_find_file() {
  local session_file_name="$1"
  local current_dir="${2:-$PWD}"
  local git_root
  local parent_dir

  current_dir="$(cd "$current_dir" 2>/dev/null && pwd -P)" || return 1

  if ! git_root=$(git -C "$current_dir" rev-parse --show-toplevel 2>/dev/null); then
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

    parent_dir=$(dirname "$current_dir")
    [[ "$parent_dir" == "$current_dir" ]] && break
    current_dir="$parent_dir"
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
  local session_dir
  local session_base
  local tmp_file

  session_dir=$(dirname -- "$session_file")
  session_base=$(basename -- "$session_file")
  tmp_file=$(mktemp "${session_dir}/.${session_base}.tmp.XXXXXX") || return 1

  chmod 600 "$tmp_file" || {
    rm -f "$tmp_file"
    return 1
  }

  printf '%s\n' "$session_id" >"$tmp_file" || {
    rm -f "$tmp_file"
    return 1
  }

  mv -f "$tmp_file" "$session_file" || {
    rm -f "$tmp_file"
    return 1
  }

  return 0
}

session_wrapper_load_id() {
  local session_file_name="$1"
  local session_file
  local session_id

  if ! session_file=$(session_wrapper_find_file "$session_file_name"); then
    return 1
  fi

  if ! session_id=$(<"$session_file"); then
    return 1
  fi

  session_id="${session_id%$'\r'}"
  if [[ -z "$session_id" ]]; then
    rm -f "$session_file"
    return 1
  fi

  printf '%s\n' "$session_id"
}
