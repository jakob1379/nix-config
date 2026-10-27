# shellcheck shell=bash
# Auto-start tmux for remote SSH sessions if the shell is interactive
if [ -z "$INSIDE_EMACS" ]; then
  # If it's a TRAMP connection (TERM is "dumb"), do not proceed with tmux
  if [ "$TERM" = "dumb" ]; then
    PS1="> "
  else
    # If not inside Emacs or a dumb terminal, start tmux if appropriate
    if [ -z "$TMUX" ] && [ -n "$PS1" ] && [ "$TERM" != "dumb" ]; then
      # one session per client, grouped on "main": shared windows, own size
      tmux has-session -t main 2>/dev/null || tmux new-session -d -s main
      tmux new-session -t main -s "ssh-$$" \; set-option -t "ssh-$$" destroy-unattached on ||
        echo "Unable to start or attach to tmux session."
    fi
  fi
fi
