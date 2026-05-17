{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  tmuxNetStatus = pkgs.writeShellApplication {
    name = "tmux-net-status";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.iputils
      pkgs.iproute2
      pkgs.tmux
    ];
    text = builtins.readFile ../../scripts/tmux/net-status.sh;
  };
  tmuxWindowLabel = pkgs.writeShellApplication {
    name = "tmux-window-label";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
    ];
    text = builtins.readFile ../../scripts/tmux/window-label.sh;
  };
in
{
  config = {
    home = {
      shell.enableBashIntegration = true;

      shellAliases = {
        noctalia-restart = "noctalia-shell list --all --json | jq -Rsc '(fromjson? // [])[]?.pid' | xargs -r kill; noctalia-shell -d";
        onefetch = "onefetch -E --nerd-fonts --no-color-palette";
        cat = "bat";
        watch = "hwatch";
        cdd = ''f(){ [ -d "$1" ] && cd "$1" || { [ -f "$1" ] && cd "$(dirname "$1")"; } || echo "No such file or directory"; }; f'';
        fm = "frogmouth";
        db = "distrobox";
        df = "duf --hide special";
        open = "xdg-open";
        nshell = ''f(){ [ $# -gt 0 ] || { echo "usage: nshell <package> [nix args...]" >&2; return 1; }; nix shell --set-env-var OMP_NIX_SHELL 1 "nixpkgs#$1" "''${@:2}"; }; f'';
        venv = ''[ -n "$VIRTUAL_ENV" ] && deactivate; . .venv/bin/activate'';
        rsync = "rsync --info=progress2";
        plasma-restart = "systemctl restart --user plasma-plasmashell";
        dcup = "docker compose up --remove-orphans";
        dcview = "docker compose config | bat -l yml";
        dk = "dragon-drop --keep";
        dx = "dragon-drop --and-exit";
        ec = ''emacsclient --no-wait --reuse-frame --alternate-editor ""'';
        cx = "codex resume";
        grep = "grep --color=auto";
        q = "qalc";
        tldr = ''tldr_wrapper() { tldr "$1" || man "$1" | bat -l man -p; } && tldr_wrapper'';
      };
    };

    programs = {
      bash = {
        enable = true;
        profileExtra = builtins.readFile ../../dotfiles/bash/.profile;
        initExtra = lib.mkOrder 2000 ''
          __nix_find_widget() {
              local selected
              selected="$(nix-find)" || return

              [[ -z "$selected" ]] && return

              READLINE_LINE="''${READLINE_LINE:0:READLINE_POINT}$selected''${READLINE_LINE:READLINE_POINT}"
              READLINE_POINT=$((READLINE_POINT + ''${#selected}))
                            }

          bind -x '"\C-x\C-w":__nix_find_widget'
          bind -m emacs-standard -x '"\C-x\C-w":__nix_find_widget'
          bind -m vi-command -x '"\C-x\C-w":__nix_find_widget'
          bind -m vi-insert -x '"\C-x\C-w":__nix_find_widget'
          bind '"\C-w": "\C-x\C-w"'
          bind -m emacs-standard '"\C-w": "\C-x\C-w"'
          bind -m vi-command '"\C-w": "\C-x\C-w"'
          bind -m vi-insert '"\C-w": "\C-x\C-w"'

          __ag_fuzzy_widget() {
              local selected
              selected="$(ag-fuzzy)" || return

              [[ -z "$selected" ]] && return

              READLINE_LINE="''${READLINE_LINE:0:READLINE_POINT}$selected''${READLINE_LINE:READLINE_POINT}"
              READLINE_POINT=$((READLINE_POINT + ''${#selected}))
                            }

          bind -m emacs-standard -x '"\ea": __ag_fuzzy_widget'
          bind -m vi-command -x '"\ea": __ag_fuzzy_widget'
          bind -m vi-insert -x '"\ea": __ag_fuzzy_widget'
          bind -x '"\eu":"up"'
        '';
        shellOptions = [ "cdspell" ];
        historyControl = [ "ignoreboth" ];
        bashrcExtra = ''
          if [[ $TERM = dumb ]]; then
              return
          fi

          if [[ -z "$SSH_CONNECTION" ]]; then
              ${pkgs.coreutils}/bin/cat ${config.xdg.cacheHome}/wal/sequences
          fi
          ${builtins.readFile ../../scripts/shell/secret-export.sh}

          eval "$(batman --export-env)"
          eval "$(command up --init bash)"
        '';
      };

      direnv = {
        enable = true;
        enableBashIntegration = true;
        nix-direnv.enable = true;
      };

      fastfetch = {
        enable = true;
      };

      fd.enable = true;

      hwatch.enable = true;

      jq = {
        enable = true;
      };

      jqp.enable = true;

      rclone = {
        enable = true;
      };

      tmux = {
        enable = true;
        newSession = true;
        clock24 = true;
        baseIndex = 1;
        escapeTime = 1;
        terminal = "tmux-256color";
        focusEvents = true;
        extraConfig = builtins.readFile ../../dotfiles/tmux/tmux.conf;
        plugins = [
          {
            plugin = pkgs.tmuxPlugins.dotbar;
            extraConfig = ''
              set -ag update-environment " SSH_CLIENT SSH_CONNECTION"
              run-shell 'client_ip=''${SSH_CLIENT%% *}; [ -z "$client_ip" ] && client_ip=''${SSH_CONNECTION%% *}; tmux set -g @tmux-net-client-host "$client_ip"; tmux set -g @tmux-net-client-port "22"; tmux set -g @tmux-net-timeout "1"'
              set -g @tmux-dotbar-session-text " #H "
              set -g status-left-length 80
              set -g @tmux-dotbar-status-left '#[bg=#0B0E14]#{?client_prefix,#[fg=#95E6CB]#[bg=#95E6CB]#[fg=#0B0E14]#[bold]#H#[nobold]#[bg=#0B0E14]#[fg=#95E6CB],#[fg=#565B66] #H }#[bg=#0B0E14]#[fg=#565B66]'
              set -g @tmux-dotbar-window-status-format " #(${tmuxWindowLabel}/bin/tmux-window-label '#{pane_current_path}' '#{pane_current_command}') "
              set -g @tmux-dotbar-right true
              set -g @tmux-dotbar-status-right-text " #(${tmuxNetStatus}/bin/tmux-net-status) "
              set -g @tmux-dotbar-ssh-enabled true
              set -g @tmux-dotbar-ssh-icon-only false
            '';
          }
        ];
      };

      zoxide = {
        enable = true;
        enableBashIntegration = true;
        options = [ "--cmd cd" ];
      };

      eza = {
        enable = true;
        enableBashIntegration = true;
        icons = "auto";
        git = true;
        extraOptions = [
          "--group-directories-first"
          "--smart-group"
        ];
      };

      oh-my-posh = {
        enable = true;
        enableBashIntegration = true;
        settings = builtins.fromJSON (
          builtins.readFile ../../dotfiles/oh-my-posh/custom-hunks-theme.omp.json
        );
      };

      fzf = {
        enable = true;
        enableBashIntegration = true;
        changeDirWidgetOptions = [
          "--preview '${pkgs.eza}/bin/eza --tree --color=always \"{}\" | head -200'"
        ];
        changeDirWidgetCommand = "fd --type d";
        fileWidgetCommand = "fd --type file --hidden --no-ignore-vcs";
        fileWidgetOptions = [
          "--preview '${pkgs.bat}/bin/bat \"{}\" --style=changes,header-filename,numbers,snip,rule --paging always --force-colorization'"
        ];
      };

      bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras; [ batman ];
        config = {
          map-syntax = [
            "*.conf:TOML"
            "*.gdextension:TOML"
            "*.kdl:java"
            ".env.*:toml"
            ".envrc:bash"
            "justfile:make"
            "u2f_keys:CSV"
          ];
        };
      };

      readline = {
        enable = true;
        extraConfig = ''
          $include /etc/inputrc
        '';
        variables = {
          completion-ignore-case = true;
          completion-prefix-display-length = 3;
          mark-symlinked-directories = true;
          show-all-if-ambiguous = true;
          show-all-if-unmodified = true;
        };
      };

      navi = {
        enable = true;
        enableBashIntegration = true;
        settings.cheats.paths = [
          "${inputs.navi-cheats-src}"
          "${inputs.navi-tldr-pages-src}"
        ];
      };

      yazi = {
        enable = true;
        shellWrapperName = "y";
      };
    };

    nix = {
      package = pkgs.nix;
      settings = {
        substituters = [
          "https://cache.nixos.org/"
          "https://jgalabs-homelab.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "jgalabs-homelab.cachix.org-1:STDTFhtj7rW1eWuCT75Ns0UDZqYu0BUTYsXeYHlbhwE="
        ];
        max-jobs = 1;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 2w";
      };
    };
  };
}
