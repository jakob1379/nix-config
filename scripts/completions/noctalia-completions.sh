#!/usr/bin/env bash
# shellcheck shell=bash

type _init_completion >/dev/null 2>&1 || return 0

__noctalia_compgen_words() {
  local list=$1
  local cur=$2
  mapfile -t COMPREPLY < <(compgen -W "$list" -- "$cur")
}

__noctalia_compgen_words_and_files() {
  local list=$1
  local cur=$2
  local word_matches=()
  local file_matches=()
  mapfile -t word_matches < <(compgen -W "$list" -- "$cur")
  mapfile -t file_matches < <(compgen -f -- "$cur")
  COMPREPLY=("${word_matches[@]}" "${file_matches[@]}")
}

__noctalia_find_subcommand() {
  local i
  for ((i = 1; i < cword; i++)); do
    case "${words[i]}" in
      msg|theme|config)
        printf '%s:%s\n' "${words[i]}" "$i"
        return
        ;;
    esac
  done
}

_noctalia_complete_theme() {
  local subcommand_index=$1
  local prev=${words[cword - 1]}
  local opts="--scheme --dark --light --both --theme-json -o -r -c --builtin-config --list-templates --default-mode --help"
  local schemes="m3-tonal-spot m3-content m3-fruit-salad m3-rainbow m3-monochrome vibrant faithful dysfunctional muted"

  case "$prev" in
    --scheme)
      __noctalia_compgen_words "$schemes" "$cur"
      return
      ;;
    --theme-json|-o|-r|-c)
      _filedir
      return
      ;;
    --default-mode)
      __noctalia_compgen_words "dark light" "$cur"
      return
      ;;
  esac

  if [[ $cur == -* ]]; then
    __noctalia_compgen_words "$opts" "$cur"
    return
  fi

  if ((cword == subcommand_index + 1)); then
    __noctalia_compgen_words_and_files "$opts" "$cur"
    return
  fi

  _filedir
}

_noctalia_complete_config() {
  local subcommand_index=$1
  local prev=${words[cword - 1]}
  local config_command=
  local config_command_index=
  local i

  for ((i = subcommand_index + 1; i < cword; i++)); do
    case "${words[i]}" in
      validate|export|settings-count|replay-report)
        config_command=${words[i]}
        config_command_index=$i
        break
        ;;
    esac
  done

  if [[ -z $config_command ]]; then
    if [[ $cur == -* ]]; then
      __noctalia_compgen_words "--help" "$cur"
      return
    fi
    __noctalia_compgen_words "validate export settings-count replay-report --help" "$cur"
    return
  fi

  case "$config_command" in
    validate)
      if [[ $cur == -* ]]; then
        __noctalia_compgen_words "--help" "$cur"
      else
        _filedir
      fi
      ;;
    export)
      if [[ $cur == -* ]]; then
        __noctalia_compgen_words "--help" "$cur"
      elif ((cword == config_command_index + 1)); then
        __noctalia_compgen_words "merged full" "$cur"
      fi
      ;;
    replay-report)
      case "$prev" in
        --target)
          _filedir -d
          return
          ;;
      esac

      if [[ $cur == -* ]]; then
        __noctalia_compgen_words "--target --flattened --force --help" "$cur"
      else
        _filedir
      fi
      ;;
    settings-count)
      if [[ $cur == -* ]]; then
        __noctalia_compgen_words "--help" "$cur"
      fi
      ;;
  esac
}

_noctalia_complete_msg() {
  local subcommand_index=$1
  local commands=(
    bar-auto-hide-set
    bar-hide
    bar-show
    bar-toggle
    bluetooth-disable
    bluetooth-enable
    bluetooth-status
    bluetooth-toggle
    brightness-down
    brightness-osd
    brightness-set
    brightness-up
    caffeine-disable
    caffeine-enable
    caffeine-toggle
    clipboard-clear
    color-scheme-get
    color-scheme-set
    config-reload
    desktop-widgets-edit
    desktop-widgets-exit
    desktop-widgets-hide
    desktop-widgets-show
    desktop-widgets-toggle
    desktop-widgets-toggle-edit
    dock-hide
    dock-reload
    dock-show
    dock-toggle
    dpms-off
    dpms-on
    effects-profile-set
    greeter-sync
    lockscreen-widgets-edit
    lockscreen-widgets-exit
    lockscreen-widgets-toggle-edit
    media
    mic-mute
    mic-volume-down
    mic-volume-set
    mic-volume-up
    nightlight-disable
    nightlight-enable
    nightlight-force-toggle
    nightlight-toggle
    notification-clear-active
    notification-clear-history
    notification-dnd-set
    notification-dnd-status
    notification-dnd-toggle
    panel-close
    panel-open
    panel-toggle
    plugin
    plugins
    power-cycle
    power-set
    screenshot-fullscreen
    screenshot-region
    session
    settings-close
    settings-open
    settings-toggle
    status
    templates-apply
    theme-mode-get
    theme-mode-set
    theme-mode-toggle
    volume-down
    volume-mute
    volume-set
    volume-up
    wallpaper-get
    wallpaper-random
    wallpaper-set
    wifi-disable
    wifi-enable
    wifi-status
    wifi-toggle
    window-switcher
  )

  if ((cword == subcommand_index + 1)); then
    __noctalia_compgen_words "--help ${commands[*]}" "$cur"
    return
  fi

  if [[ ${words[$((subcommand_index + 1))]} == session ]] && ((cword == subcommand_index + 2)); then
    __noctalia_compgen_words "lock suspend lock-and-suspend logout reboot shutdown" "$cur"
  fi
}

_noctalia_complete() {
  local cur prev words cword
  _init_completion -n : || return

  local subcommand_info
  local subcommand
  local subcommand_index
  subcommand_info=$(__noctalia_find_subcommand)

  if [[ -n $subcommand_info ]]; then
    subcommand=${subcommand_info%%:*}
    subcommand_index=${subcommand_info#*:}

    case "$subcommand" in
      theme)
        _noctalia_complete_theme "$subcommand_index"
        ;;
      config)
        _noctalia_complete_config "$subcommand_index"
        ;;
      msg)
        _noctalia_complete_msg "$subcommand_index"
        ;;
    esac
    return
  fi

  if [[ $cur == -* ]]; then
    __noctalia_compgen_words "--help -h --version -v --daemon -d" "$cur"
    return
  fi

  __noctalia_compgen_words "msg theme config --help -h --version -v --daemon -d" "$cur"
}

complete -o filenames -F _noctalia_complete noctalia
