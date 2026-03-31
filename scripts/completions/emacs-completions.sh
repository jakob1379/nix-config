#!/usr/bin/env bash
# shellcheck shell=bash
# Bash completion for emacs and emacsclient

# Exit quietly if bash-completion isn't present
type _init_completion >/dev/null 2>&1 || return 0

# Helpers to avoid SC2207
__compgen_words() {
  # Usage: __compgen_words "word1 word2 ..." CURRENT [prefix_for_rewrite]
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

__compgen_files() {
  # Usage: __compgen_files CURRENT [prefix_for_rewrite]
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

# ----------------------------
# emacsclient completion
# ----------------------------

_emacsclient_opts_short=(
  -V -H -t -nw -tty -c -r -F -e -n -w -q -u -d -s -f -a -T
)

_emacsclient_opts_long=(
  --version
  --help
  --tty
  --no-window-system
  --create-frame
  --reuse-frame
  --frame-parameters=
  --eval
  --no-wait
  --timeout=
  --quiet
  --suppress-output
  --display=
  --parent-id=
  --socket-name=
  --server-file=
  --alternate-editor=
  --tramp=
)

_emacsclient_complete() {
  # shellcheck disable=SC2034  # words/cword are used implicitly by _init_completion
  local cur prev words cword
  _init_completion -n : || return

  # --opt=value
  if [[ $cur == --*=* ]]; then
    local opt=${cur%%=*}
    local val=${cur#*=}
    case " $opt " in
      " --timeout= " | " --parent-id= " )
        COMPREPLY=()
        return
        ;;
      " --display= " )
        __compgen_words ":0 :1 localhost:0" "$val" "--display="
        return
        ;;
      " --socket-name= " | " --server-file= " | " --alternate-editor= " | " --tramp= " )
        __compgen_files "$val" "${opt}="
        return
        ;;
      " --frame-parameters= " )
        COMPREPLY=()
        return
        ;;
    esac
  fi

  # prev expects arg
  case "$prev" in
    -w|-F|--frame-parameters=|--parent-id=)
      COMPREPLY=()
      return
      ;;
    -d|--display=)
      __compgen_words ":0 :1 localhost:0" "$cur"
      return
      ;;
    -s|--socket-name=|-f|--server-file=|-a|--alternate-editor=|-T|--tramp=)
      __compgen_files "$cur"
      return
      ;;
  esac

  # options
  if [[ $cur == -* ]]; then
    local all_opts=( "${_emacsclient_opts_short[@]}" "${_emacsclient_opts_long[@]}" )
    __compgen_words "${all_opts[*]}" "$cur"
    return
  fi

  # positional files
  _filedir
}

# ----------------------------
# emacs completion
# ----------------------------

_emacs_opts_short=(
  -q -nl -nsl -nw -Q -x -d -t -u -f -l -L -T
  -bg -D -bd -bw -cr -fn -fg -fh -fs -fw -mm -g -nbi -ib -lsp -ms -r -rv -vb
)

_emacs_opts_long=(
  --batch
  --chdir
  --daemon
  --bg-daemon=
  --fg-daemon=
  --debug-init
  --display=
  --module-assertions
  --dump-file
  --fingerprint
  --seccomp=
  --no-build-details
  --no-desktop
  --no-init-file
  --no-loadup
  --no-site-file
  --no-x-resources
  --no-site-lisp
  --no-splash
  --no-window-system
  --init-directory=
  --quick
  --script
  --terminal=
  --user=
  --directory=
  --eval
  --execute
  --file
  --find-file
  --funcall=
  --insert
  --kill
  --load
  --visit
  --background-color=
  --basic-display
  --border-color=
  --border-width=
  --color
  --color=
  --cursor-color=
  --font=
  --foreground-color=
  --fullheight
  --fullscreen
  --fullwidth
  --maximized
  --geometry=
  --no-bitmap-icon
  --iconic
  --internal-border=
  --line-spacing=
  --mouse-color=
  --name=
  --no-blinking-cursor
  --reverse-video
  --title=
  --vertical-scroll-bars
  --xrm
  --parent-id
  --help
  --version
)

_emacs_complete() {
  # shellcheck disable=SC2034  # words/cword are used implicitly by _init_completion
  local cur prev words cword
  _init_completion -n : || return

  # +LINE[:COLUMN]
  if [[ $cur == +* ]]; then
    if [[ $cur == +([0-9])?(:+([0-9])) ]]; then
      COMPREPLY=()
    else
      __compgen_words "+1 +10 +100 +1:1 +10:1" "$cur"
    fi
    return
  fi

  # --opt=value
  if [[ $cur == --*=* ]]; then
    local opt=${cur%%=*}
    local val=${cur#*=}
    case " $opt " in
      " --display " )
        __compgen_words ":0 :1 localhost:0" "$val" "--display="
        return
        ;;
      " --bg-daemon " | " --fg-daemon " )
        COMPREPLY=()
        return
        ;;
      " --dump-file " | " --seccomp " | " --init-directory " | \
      " --directory " | " --file " | " --find-file " | " --insert " | \
      " --load " | " --visit " | " --font " | " --xrm " )
        __compgen_files "$val" "${opt}="
        return
        ;;
      " --background-color " | " --border-color " | " --cursor-color " | \
      " --foreground-color " | " --mouse-color " )
        __compgen_words "black white red green blue yellow magenta cyan gray grey" "$val" "${opt}="
        return
        ;;
      " --geometry " )
        __compgen_words "80x24 100x30 1920x1080+0+0" "$val" "${opt}="
        return
        ;;
      " --border-width " | " --internal-border " | " --line-spacing " | " --parent-id " | \
      " --name " | " --title " | " --color " )
        COMPREPLY=()
        return
        ;;
    esac
  fi

  # prev expects arg
  case "$prev" in
    -d|--display)
      __compgen_words ":0 :1 localhost:0" "$cur"
      return
      ;;
    --bg-daemon|--fg-daemon)
      COMPREPLY=()
      return
      ;;
    --chdir|-L|--directory|--dump-file|--seccomp|--init-directory|--script|\
    --file|--find-file|--insert|--load|--visit|-l|--font|-fn|--xrm)
      _filedir
      return
      ;;
    -bw|--border-width|-ib|--internal-border|-lsp|--line-spacing|--parent-id)
      COMPREPLY=()
      return
      ;;
    -t|--terminal|-u|--user|-f|--funcall|-T|--title|--name|--color|--geometry|--eval|--execute)
      COMPREPLY=()
      return
      ;;
  esac

  # options (+ GNU single-dash long aliases)
  if [[ $cur == -* ]]; then
    local all_opts=(
      "${_emacs_opts_short[@]}"
      "${_emacs_opts_long[@]}"
      -batch -chdir -daemon -bg-daemon -fg-daemon -debug-init -display \
      -module-assertions -dump-file -fingerprint -seccomp -no-build-details \
      -no-desktop -no-init-file -no-loadup -no-site-file -no-x-resources \
      -no-site-lisp -no-splash -no-window-system -init-directory -quick \
      -script -terminal -user -directory -eval -execute -file -find-file \
      -funcall -insert -kill -load -visit -background-color -basic-display \
      -border-color -border-width -color -cursor-color -font -foreground-color \
      -fullheight -fullscreen -fullwidth -maximized -geometry -no-bitmap-icon \
      -iconic -internal-border -line-spacing -mouse-color -name \
      -no-blinking-cursor -reverse-video -title -vertical-scroll-bars -xrm \
      -parent-id -help -version
    )
    __compgen_words "${all_opts[*]}" "$cur"
    return
  fi

  # positional files
  _filedir
}

# ----------------------------
# Registration
# ----------------------------

complete -o filenames -F _emacs_complete emacs
complete -o filenames -F _emacsclient_complete emacsclient
