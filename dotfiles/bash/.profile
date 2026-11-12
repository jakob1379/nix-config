# shellcheck shell=bash
# Auto-start tmux for interactive login shells, local and SSH
if [ -z "$INSIDE_EMACS" ]; then
  # If it's a TRAMP connection (TERM is "dumb"), do not proceed with tmux
  if [ "$TERM" = "dumb" ]; then
    PS1="> "
  else
    # If not inside Emacs or a dumb terminal, start tmux if appropriate
    if [ -z "$TMUX" ] && [ -n "$PS1" ] && [ "$TERM" != "dumb" ]; then
      # one session per client, grouped per niri workspace (else "main"): shared windows, own size
      group=main
      if [ -n "$NIRI_SOCKET" ]; then
        ws=$(niri msg -j workspaces 2>/dev/null | jq -r '.[] | select(.is_focused) | .id' 2>/dev/null)
        [ -n "$ws" ] && group="ws-$ws"
      fi
      tmux has-session -t "$group" 2>/dev/null ||
        systemd-run --user --scope --quiet --collect tmux new-session -d -s "$group" 2>/dev/null ||
        tmux new-session -d -s "$group"
      tmux new-session -t "$group" -s "ssh-$$" \; set-option -t "ssh-$$" destroy-unattached on ||
        echo "Unable to start or attach to tmux session."
    fi
  fi
fi
