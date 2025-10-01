#!/usr/bin/env bash
# bash completion for emacs
# shellcheck disable=SC2034,SC2207

# To use:
# - Place this file at ~/.local/share/bash-completion/completions/emacs
#   or source it from your ~/.bashrc
# - Requires bash-completion

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

# Options that take an argument (both short and long forms)
_emacs_opts_with_arg_short=(-d -t -u -f -l -L -T -bg -bd -bw -cr -fn -fg -g -ib -lsp -ms)
_emacs_opts_with_arg_long=(
  --chdir
  --bg-daemon=
  --fg-daemon=
  --display=
  --dump-file
  --seccomp=
  --init-directory=
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
  --load
  --visit
  --background-color=
  --border-color=
  --border-width=
  --cursor-color=
  --font=
  --foreground-color=
  --geometry=
  --internal-border=
  --line-spacing=
  --mouse-color=
  --name=
  --title=
  --xrm
  --parent-id
)

# Options whose arg is typically a file/path
_emacs_file_arg_opts=(
  --chdir -d
  --dump-file
  --seccomp=
  --init-directory=
  --script
  --directory= -L
  --file --find-file --insert --load --visit -l
  --font= -fn
  --xrm
)

# Options whose arg is a display
_emacs_display_arg_opts=(--display= -d)

# Options with numeric args
_emacs_numeric_arg_opts=(--border-width= -bw --internal-border= -ib --line-spacing= -lsp --parent-id)

# Simple color placeholders
_emacs_color_opts=(--background-color= -bg --border-color= -bd --cursor-color= -cr --foreground-color= -fg --mouse-color= -ms)

_emacs_complete()
{
  local cur prev words cword
  _init_completion -n : || return

  # Handle +LINE and +LINE:COLUMN pseudo-args:
  # If current token starts with +, don't attempt filename completion.
  if [[ $cur == +* ]]; then
    # Basic hinting for formats +N or +N:M (digits only)
    if [[ $cur == +([0-9])?(:+([0-9])) ]]; then
      COMPREPLY=()
    else
      COMPREPLY=( $(compgen -W "+1 +10 +100 +1:1 +10:1" -- "$cur") )
    fi
    return
  fi

  # Handle --opt=value forms
  if [[ $cur == --*=* ]]; then
    local opt=${cur%%=*}
    local val=${cur#*=}

    case " $opt " in
      # display
      " --display " )
        COMPREPLY=( $(compgen -W ":0 :1 localhost:0" -- "$cur") )
        return
        ;;
      # file-like args after =
      " --bg-daemon " | " --fg-daemon " )
        # Name is free-form; no completion
        COMPREPLY=()
        return
        ;;
      " --dump-file " | " --seccomp " | " --init-directory " | \
      " --directory " | " --file " | " --find-file " | " --insert " | \
      " --load " | " --visit " | " --font " )
        local prefix="${opt}="
        COMPREPLY=( $(compgen -f -- "$val") )
        COMPREPLY=( "${COMPREPLY[@]/#/$prefix}" )
        return
        ;;
      # colors: provide common color names
      " --background-color " | " --border-color " | " --cursor-color " | \
      " --foreground-color " | " --mouse-color " )
        local prefix="${opt}="
        local colors="black white red green blue yellow magenta cyan gray grey"
        COMPREPLY=( $(compgen -W "$colors" -- "$val") )
        COMPREPLY=( "${COMPREPLY[@]/#/$prefix}" )
        return
        ;;
      # geometry
      " --geometry " )
        # simple hints; users can type full WxH+X+Y
        local prefix="${opt}="
        local hints="80x24 100x30 1920x1080+0+0"
        COMPREPLY=( $(compgen -W "$hints" -- "$val") )
        COMPREPLY=( "${COMPREPLY[@]/#/$prefix}" )
        return
        ;;
      # numeric-like; no completion
      " --border-width " | " --internal-border " | " --line-spacing " | " --parent-id " )
        COMPREPLY=()
        return
        ;;
      # generic string args
      " --name " | " --title " | " --color " )
        COMPREPLY=()
        return
        ;;
    esac
  fi

  # If previous word is an option expecting an argument (space separated)
  case "$prev" in
    # display
    -d|--display)
      COMPREPLY=( $(compgen -W ":0 :1 localhost:0" -- "$cur") )
      return
      ;;
    # daemon names: free-form
    --bg-daemon|--fg-daemon)
      COMPREPLY=()
      return
      ;;
    # files/dirs
    --chdir|-L|--directory|--dump-file|--seccomp|--init-directory|--script|\
    --file|--find-file|--insert|--load|--visit|-l|--font|-fn|--xrm)
      _filedir
      return
      ;;
    # numeric-ish
    -bw|--border-width|-ib|--internal-border|-lsp|--line-spacing|--parent-id)
      COMPREPLY=()
      return
      ;;
    # strings
    -t|--terminal|-u|--user|-f|--funcall|-T|--title|--name|--color|--geometry)
      COMPREPLY=()
      return
      ;;
    # eval/execute elisp: leave empty
    --eval|--execute)
      COMPREPLY=()
      return
      ;;
  esac

  # If current starts with -, complete options (support GNU single-dash long opts)
  if [[ $cur == -* ]]; then
    local all_opts=(
      "${_emacs_opts_short[@]}"
      "${_emacs_opts_long[@]}"
      # Single-dash long aliases for common ones (per help text hint)
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
    COMPREPLY=( $(compgen -W "${all_opts[*]}" -- "$cur") )
    return
  fi

  # Positional args: filenames (and +LINE[:COLUMN] handled earlier)
  _filedir
}

# Register completion for emacs command
complete -o filenames -F _emacs_complete emacs
