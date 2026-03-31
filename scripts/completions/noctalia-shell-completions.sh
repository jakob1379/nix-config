#!/usr/bin/env bash
# shellcheck shell=bash

type _init_completion >/dev/null 2>&1 || return 0
type compgen >/dev/null 2>&1 || return 0
type complete >/dev/null 2>&1 || return 0

_noctalia_shell_compgen_words() {
  local list=$1
  local cur=$2
  local prefix=${3-}

  mapfile -t COMPREPLY < <(compgen -W "$list" -- "$cur")
  if [[ -n $prefix ]]; then
    local i
    for i in "${!COMPREPLY[@]}"; do
      COMPREPLY[i]="${prefix}${COMPREPLY[i]}"
    done
  fi
}

_noctalia_shell_compgen_files() {
  local cur=$1
  local prefix=${2-}

  mapfile -t COMPREPLY < <(compgen -f -- "$cur")
  if [[ -n $prefix ]]; then
    local i
    for i in "${!COMPREPLY[@]}"; do
      COMPREPLY[i]="${prefix}${COMPREPLY[i]}"
    done
  fi
}

_noctalia_shell_configs() {
  local base extra dir item
  local -a roots=()

  base="${XDG_CONFIG_HOME:-$HOME/.config}"
  roots+=("$base")

  IFS=':' read -r -a extra <<< "${XDG_CONFIG_DIRS:-/etc/xdg}"
  for dir in "${extra[@]}"; do
    [[ -n "$dir" ]] && roots+=("$dir")
  done

  for dir in "${roots[@]}"; do
    [[ -d "$dir/quickshell" ]] || continue

    if [[ -f "$dir/quickshell/shell.qml" ]]; then
      printf '%s\n' default
      continue
    fi

    for item in "$dir"/quickshell/*; do
      [[ -d "$item" && -f "$item/shell.qml" ]] || continue
      basename "$item"
    done
  done | sort -u
}

_noctalia_shell_instance_ids() {
  if command -v jq >/dev/null 2>&1; then
    noctalia-shell list --all --json 2>/dev/null | jq -r '.[].id // empty' 2>/dev/null
  fi
}

_noctalia_shell_instance_pids() {
  if command -v jq >/dev/null 2>&1; then
    noctalia-shell list --all --json 2>/dev/null | jq -r '.[].pid // empty' 2>/dev/null
  fi
}

_noctalia_shell_ipc_show_cache() {
  if [[ -z ${__NOCTALIA_SHELL_IPC_SHOW_CACHE-} ]]; then
    __NOCTALIA_SHELL_IPC_SHOW_CACHE="$(noctalia-shell ipc --newest show 2>/dev/null || true)"
  fi
  printf '%s\n' "$__NOCTALIA_SHELL_IPC_SHOW_CACHE"
}

_noctalia_shell_ipc_targets() {
  local line
  while IFS= read -r line; do
    [[ $line == target\ * ]] || continue
    printf '%s\n' "${line#target }"
  done < <(_noctalia_shell_ipc_show_cache)
}

_noctalia_shell_ipc_functions_for_target() {
  local wanted=$1
  local line current=""

  while IFS= read -r line; do
    if [[ $line == target\ * ]]; then
      current="${line#target }"
      continue
    fi

    if [[ $current == "$wanted" && $line == "  function "* ]]; then
      line="${line#  function }"
      printf '%s\n' "${line%%(*}"
    fi
  done < <(_noctalia_shell_ipc_show_cache)
}

_noctalia_shell_ipc_properties_for_target() {
  local wanted=$1
  local line current=""

  while IFS= read -r line; do
    if [[ $line == target\ * ]]; then
      current="${line#target }"
      continue
    fi

    if [[ $current == "$wanted" && $line == "  property "* ]]; then
      line="${line#  property }"
      printf '%s\n' "${line%%:*}"
    fi
  done < <(_noctalia_shell_ipc_show_cache)
}

_noctalia_shell_option_takes_value() {
  case "$1" in
    -p|--path|-c|--config|-m|--manifest|-i|--id|--pid|--debug|-t|--tail|-r|--rules|--log-rules)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

_noctalia_shell_complete_option_value() {
  local opt=$1
  local cur=$2
  local prefix=${3-}
  local words

  case "$opt" in
    -p|--path|--path=|-m|--manifest|--manifest=)
      _noctalia_shell_compgen_files "$cur" "$prefix"
      ;;
    -c|--config|--config=)
      words="$(_noctalia_shell_configs | tr '\n' ' ')"
      _noctalia_shell_compgen_words "$words" "$cur" "$prefix"
      ;;
    -i|--id|--id=)
      words="$(_noctalia_shell_instance_ids | tr '\n' ' ')"
      _noctalia_shell_compgen_words "$words" "$cur" "$prefix"
      ;;
    --pid|--pid=)
      words="$(_noctalia_shell_instance_pids | tr '\n' ' ')"
      _noctalia_shell_compgen_words "$words" "$cur" "$prefix"
      ;;
    *)
      COMPREPLY=()
      ;;
  esac
}

_noctalia_shell_collect_positionals() {
  local start_idx=$1
  local -n out=$2
  local i j token expect_value=0

  out=()
  for ((i = start_idx; i < cword; i++)); do
    token=${words[i]}

    if (( expect_value )); then
      expect_value=0
      continue
    fi

    if [[ $token == -- ]]; then
      for ((j = i + 1; j < cword; j++)); do
        out+=("${words[j]}")
      done
      break
    fi

    if _noctalia_shell_option_takes_value "$token"; then
      expect_value=1
      continue
    fi

    if [[ $token == --*=* ]]; then
      continue
    fi

    if [[ $token == -* ]]; then
      continue
    fi

    out+=("$token")
  done
}

_noctalia_shell_complete() {
  local cur prev words cword
  _init_completion -n : || return

  local root_opts root_subcommands config_opts instance_opts logging_opts
  local log_opts list_opts kill_opts ipc_opts ipc_prop_opts msg_opts
  root_opts="-h --help -V --version -n --no-duplicate -d --daemonize -p --path -c --config -m --manifest --no-color --log-times --log-rules -v --verbose --debug --waitfordebug"
  root_subcommands="log list kill ipc msg"
  config_opts="-p --path -c --config -m --manifest -n --newest"
  instance_opts="-i --id --pid"
  logging_opts="--no-color --log-times --log-rules -v --verbose"
  log_opts="-h --help -t --tail -f --follow -r --rules $instance_opts $config_opts $logging_opts"
  list_opts="-h --help -a --all -j --json --show-dead $config_opts"
  kill_opts="-h --help $instance_opts $config_opts"
  ipc_opts="-h --help $instance_opts $config_opts"
  ipc_prop_opts="$ipc_opts"
  msg_opts="-h --help -s --show $instance_opts $config_opts"

  case "$prev" in
    -p|--path|-c|--config|-m|--manifest|-i|--id|--pid|--debug|-t|--tail|-r|--rules|--log-rules)
      _noctalia_shell_complete_option_value "$prev" "$cur"
      return
      ;;
  esac

  if [[ $cur == --*=* ]]; then
    local opt val
    opt=${cur%%=*}
    val=${cur#*=}
    _noctalia_shell_complete_option_value "${opt}=" "$val" "${opt}="
    return
  fi

  local cmd1="" cmd2="" cmd3=""
  local cmd1_idx=-1 cmd2_idx=-1 cmd3_idx=-1
  local i token expect_value=0

  for ((i = 1; i < cword; i++)); do
    token=${words[i]}

    if (( expect_value )); then
      expect_value=0
      continue
    fi

    if _noctalia_shell_option_takes_value "$token"; then
      expect_value=1
      continue
    fi

    if [[ $token == --*=* ]]; then
      continue
    fi

    if [[ -z $cmd1 ]]; then
      case "$token" in
        log|list|kill|ipc|msg)
          cmd1=$token
          cmd1_idx=$i
          continue
          ;;
      esac
    fi

    if [[ $cmd1 == ipc && -z $cmd2 ]]; then
      case "$token" in
        show|call|prop)
          cmd2=$token
          cmd2_idx=$i
          continue
          ;;
      esac
    fi

    if [[ $cmd1 == ipc && $cmd2 == prop && -z $cmd3 ]]; then
      case "$token" in
        get)
          cmd3=$token
          cmd3_idx=$i
          continue
          ;;
      esac
    fi
  done

  if [[ -z $cmd1 ]]; then
    if [[ $cur == -* ]]; then
      _noctalia_shell_compgen_words "$root_opts" "$cur"
    else
      _noctalia_shell_compgen_words "$root_subcommands" "$cur"
    fi
    return
  fi

  case "$cmd1" in
    log)
      if [[ $cur == -* ]]; then
        _noctalia_shell_compgen_words "$log_opts" "$cur"
      else
        local -a pos_log=()
        _noctalia_shell_collect_positionals "$((cmd1_idx + 1))" pos_log
        if [[ ${#pos_log[@]} -eq 0 ]]; then
          _noctalia_shell_compgen_files "$cur"
        else
          COMPREPLY=()
        fi
      fi
      ;;
    list)
      if [[ $cur == -* ]]; then
        _noctalia_shell_compgen_words "$list_opts" "$cur"
      else
        COMPREPLY=()
      fi
      ;;
    kill)
      if [[ $cur == -* ]]; then
        _noctalia_shell_compgen_words "$kill_opts" "$cur"
      else
        COMPREPLY=()
      fi
      ;;
    ipc)
      if [[ -z $cmd2 ]]; then
        if [[ $cur == -* ]]; then
          _noctalia_shell_compgen_words "$ipc_opts" "$cur"
        else
          _noctalia_shell_compgen_words "show call prop" "$cur"
        fi
        return
      fi

      case "$cmd2" in
        show)
          if [[ $cur == -* ]]; then
            _noctalia_shell_compgen_words "$ipc_opts" "$cur"
          else
            COMPREPLY=()
          fi
          ;;
        call)
          if [[ $cur == -* ]]; then
            _noctalia_shell_compgen_words "$ipc_opts" "$cur"
            return
          fi

          local -a pos_call=()
          local words_targets words_functions
          _noctalia_shell_collect_positionals "$((cmd2_idx + 1))" pos_call

          if [[ ${#pos_call[@]} -eq 0 ]]; then
            words_targets="$(_noctalia_shell_ipc_targets | tr '\n' ' ')"
            _noctalia_shell_compgen_words "$words_targets" "$cur"
          elif [[ ${#pos_call[@]} -eq 1 ]]; then
            words_functions="$(_noctalia_shell_ipc_functions_for_target "${pos_call[0]}" | tr '\n' ' ')"
            _noctalia_shell_compgen_words "$words_functions" "$cur"
          else
            COMPREPLY=()
          fi
          ;;
        prop)
          if [[ -z $cmd3 ]]; then
            if [[ $cur == -* ]]; then
              _noctalia_shell_compgen_words "$ipc_prop_opts" "$cur"
            else
              _noctalia_shell_compgen_words "get" "$cur"
            fi
            return
          fi

          if [[ $cmd3 == get ]]; then
            if [[ $cur == -* ]]; then
              _noctalia_shell_compgen_words "$ipc_prop_opts" "$cur"
              return
            fi

            local -a pos_get=()
            local words_targets words_props
            _noctalia_shell_collect_positionals "$((cmd3_idx + 1))" pos_get

            if [[ ${#pos_get[@]} -eq 0 ]]; then
              words_targets="$(_noctalia_shell_ipc_targets | tr '\n' ' ')"
              _noctalia_shell_compgen_words "$words_targets" "$cur"
            elif [[ ${#pos_get[@]} -eq 1 ]]; then
              words_props="$(_noctalia_shell_ipc_properties_for_target "${pos_get[0]}" | tr '\n' ' ')"
              _noctalia_shell_compgen_words "$words_props" "$cur"
            else
              COMPREPLY=()
            fi
          fi
          ;;
      esac
      ;;
    msg)
      if [[ $cur == -* ]]; then
        _noctalia_shell_compgen_words "$msg_opts" "$cur"
        return
      fi

      local -a pos_msg=()
      local words_targets words_functions
      _noctalia_shell_collect_positionals "$((cmd1_idx + 1))" pos_msg

      if [[ ${#pos_msg[@]} -eq 0 ]]; then
        words_targets="$(_noctalia_shell_ipc_targets | tr '\n' ' ')"
        _noctalia_shell_compgen_words "$words_targets" "$cur"
      elif [[ ${#pos_msg[@]} -eq 1 ]]; then
        words_functions="$(_noctalia_shell_ipc_functions_for_target "${pos_msg[0]}" | tr '\n' ' ')"
        _noctalia_shell_compgen_words "$words_functions" "$cur"
      else
        COMPREPLY=()
      fi
      ;;
  esac
}

complete -F _noctalia_shell_complete noctalia-shell
