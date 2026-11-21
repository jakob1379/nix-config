__rg_fuzzy_widget() {
  local selected
  selected="$(rg-fuzzy)" || return

  [[ -z "$selected" ]] && return

  READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}$selected${READLINE_LINE:READLINE_POINT}"
  READLINE_POINT=$((READLINE_POINT + ${#selected}))
}

bind -m emacs-standard -x '"\ea": __rg_fuzzy_widget'
bind -m vi-command -x '"\ea": __rg_fuzzy_widget'
bind -m vi-insert -x '"\ea": __rg_fuzzy_widget'
bind -x '"\eu":"up"'

# flyline replaces readline's key loop, so `bind -x` never fires
# under it -- not even for keys it has no binding of its own for.
# Its runBashCommand action is the same contract: it exports
# READLINE_LINE/POINT/MARK, runs the command with the terminal
# cooked (so fzf draws), then reads them back into its buffer.
# The bind -x lines above stay for shells where flyline declines
# to load, e.g. INSIDE_EMACS.
if [[ $(type -t flyline) == builtin ]]; then
  # fzf binds \ec with a readline macro rather than a function,
  # so wrap __fzf_cd__ to get something runBashCommand can call.
  __fzf_cd_widget() { local out; out=$(__fzf_cd__) && eval "$out"; }

  # `flyline key list` only prints an 80-col box table with
  # wrapped cells; stitch each row's fragments back together.
  __flyline_keys_widget() {
    flyline key list | awk -F'│' '
      function flush() {
        if (n && c[2] !~ /Key\(s\)/) { $0 = c[2] "\t" c[4] "\t" c[5] "\t" c[3]; gsub(/ +/, " "); print }
        n = 0; delete c
      }
      /^[├╰]/ || /Keybindings:/ { flush(); next }
      NF == 6 { n = 1; for (i = 2; i <= 5; i++) c[i] = c[i] substr($i, 2, length($i) - 2) }
      END { flush() }
    ' | column -t -s $'\t' | fzf --no-sort --prompt='keys> ' >/dev/null
  }

  flyline key bind Ctrl+t 'always=runBashCommand(fzf-file-widget)'
  flyline key bind Alt+c  'always=runBashCommand(__fzf_cd_widget)'
  flyline key bind Alt+a  'always=runBashCommand(__rg_fuzzy_widget)'
  flyline key bind Alt+u  'always=runBashCommand(up)'
  flyline key bind Alt+k  'always=runBashCommand(__flyline_keys_widget)'

  flyline set-cursor --interpolate none --effect none
fi
