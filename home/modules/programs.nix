{
  config,
  pkgs,
  inputs,
  system,
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
  imports = [
    inputs.nix-index-database.homeModules.default
  ];

  options = {
    customGit = {
      userName = lib.mkOption {
        type = lib.types.str;
        default = "Your Name";
        description = "Default Git user name.";
      };
      userEmail = lib.mkOption {
        type = lib.types.str;
        default = "your.email@example.com";
        description = "Default Git user email.";
      };
    };

    customSsh = {
      enableKeepassxc = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable KeepassXC integration for SSH connections.";
      };
    };
  };

  config =
    let
      sshSocketDir = config.home.homeDirectory + "/.ssh/sockets";
    in
    {
      home = {
        packages = [
          pkgs.agent-browser
          inputs.numtide-llm-agents.packages.${system}.open-code-review
        ];
        shell.enableBashIntegration = true;
        activation.ensureSshSocketsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${pkgs.coreutils}/bin/mkdir -p "${sshSocketDir}"
          ${pkgs.coreutils}/bin/chmod 700 "${config.home.homeDirectory}/.ssh"
          ${pkgs.coreutils}/bin/chmod 700 "${sshSocketDir}"
        '';

        file =
          lib.optionalAttrs config.customSsh.enableKeepassxc {
            ".ssh/keepassxc-prompt".source = ../../scripts/ssh/keepassxc-prompt.sh;
          }
          # Claude Code plugins, linked as whole-directory symlinks into
          # ~/.claude/skills instead of via programs.claude-code.plugins. That
          # option wraps each plugin in a derivation of per-entry symlinks, and
          # Claude Code >= 2.1.2xx rejects declared paths whose realpath leaves
          # the plugin directory ("path escapes plugin directory"). A single
          # symlink to the source keeps every declared path inside it.
          # Pinned via flake.lock; `nix flake update` bumps them.
          # open-code-review needs the `ocr` binary on PATH (see home.packages).
          // lib.mapAttrs' (name: src: lib.nameValuePair ".claude/skills/${name}" { source = src; }) {
            mattpocock-skills = inputs.mattpocock-skills-src;
            open-code-review = "${inputs.open-code-review-src}/plugins/open-code-review/claude-code";
            ponytail = inputs.ponytail-src;
            superpowers = inputs.superpowers-src;
          };
      };

      programs = {
        bash = {
          enable = true;
          profileExtra = builtins.readFile ../../dotfiles/bash/.profile;
          initExtra = lib.mkMerge [
            (lib.mkOrder 3000 ''
              enable -f ${pkgs.flyline}/lib/libflyline.so flyline

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

              __rg_fuzzy_widget() {
                local selected
                selected="$(rg-fuzzy)" || return

                [[ -z "$selected" ]] && return

                READLINE_LINE="''${READLINE_LINE:0:READLINE_POINT}$selected''${READLINE_LINE:READLINE_POINT}"
                READLINE_POINT=$((READLINE_POINT + ''${#selected}))
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

                flyline key bind Ctrl+t 'always=runBashCommand(fzf-file-widget)'
                flyline key bind Alt+c  'always=runBashCommand(__fzf_cd_widget)'
                flyline key bind Ctrl+w 'always=runBashCommand(__nix_find_widget)'
                flyline key bind Alt+a  'always=runBashCommand(__rg_fuzzy_widget)'
                flyline key bind Alt+u  'always=runBashCommand(up)'

                flyline set-agent-mode \
                  --system-prompt "Be concise. Answer with a JSON array of at most 3 items with objects containing: command and description. Command will be a Bash command. " \
                  --trigger-prefix ': ' \
                  --command '${lib.getExe pkgs.claude-code} --effort low --print'
              fi
            '')
          ];
          shellOptions = [ "cdspell" ];
          historyControl = [ "ignoreboth" ];
          bashrcExtra = ''
            if [[ $TERM = dumb ]]; then
                return
            fi

            if [[ -z "$SSH_CONNECTION" && -r ${config.xdg.cacheHome}/wallust/sequences ]]; then
                ${pkgs.coreutils}/bin/cat ${config.xdg.cacheHome}/wallust/sequences
            fi
            ${builtins.readFile ../../scripts/shell/secret-export.sh}

            eval "$(command up --init bash)"
            source <(command git-worktree-cd --init bash)
          '';
        };

        claude-code = {
          enable = true;
          context = ../../dotfiles/AGENTS.md;

          skills = {
            aggregate-code-quality-report = ../../dotfiles/skills/aggregate-code-quality-report;
            converge-review = ../../dotfiles/skills/converge-review;
            frontend-design = "${inputs.claude-code-src}/plugins/frontend-design/skills/frontend-design";
            unslop = "${inputs.cursor-plugins-src}/pstack/skills/unslop";
          };

          mcpServers.context7 = {
            type = "http";
            url = "https://mcp.context7.com/mcp";
          };

          settings = {
            # Superpowers ships no telemetry today (audited: no network calls,
            # no SUPERPOWERS_* env reads). Set preemptively so any future
            # opt-out telemetry stays off by default.
            env.SUPERPOWERS_DISABLE_TELEMETRY = "1";
            autoMemoryEnabled = false;
            tui = "fullscreen";
            sandbox.enabled = true;
            agentPushNotifEnabled = true;
            includeCoAuthoredBy = false;
            attribution.sessionUrl = false;
            permissions.defaultMode = "auto";
            statusLine = {
              type = "command";
              command = "bash ~/.claude/statusline-command.sh";
            };
          };
        };

        direnv = {
          enable = true;
          enableBashIntegration = true;
          nix-direnv.enable = true;
        };

        emacs = {
          enable = true;
          package = pkgs.emacs31-pgtk;
          extraPackages =
            epkgs: with epkgs; [
              treesit-grammars.with-all-grammars
            ];
        };

        fastfetch = {
          enable = true;
          settings = {
            "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
            display = {
              separator = "  ";
              freq.ndigits = 1;
            };
            modules = [
              {
                type = "title";
                keyWidth = 10;
              }
              "break"
              {
                type = "os";
                key = " 󰟀 OS";
                keyColor = "yellow";
              }
              {
                type = "kernel";
                key = "├  Kernel";
                keyColor = "yellow";
              }
              {
                type = "packages";
                key = "├ 󰏖 Packages";
                keyColor = "yellow";
              }
              {
                type = "shell";
                key = "├ 󰞷 Shell";
                keyColor = "yellow";
              }
              {
                type = "localip";
                key = "├ 󰩟 Local IP";
                keyColor = "yellow";
              }
              {
                type = "uptime";
                key = "└ 󰅐 Uptime";
                keyColor = "yellow";
              }
              "break"
              {
                type = "command";
                key = " 󰍹 Session";
                keyColor = "blue";
                text = ''
                  if [ -n "$WAYLAND_DISPLAY$DISPLAY" ]; then echo "graphical (''${XDG_SESSION_TYPE:-x11})"; else echo "headless''${SSH_CONNECTION:+ (ssh)}"; fi
                '';
              }
              {
                type = "de";
                key = "├ 󰜬 DE";
                keyColor = "blue";
              }
              {
                type = "wm";
                key = "├ 󰨇 Window Manager";
                keyColor = "blue";
              }
              {
                type = "lm";
                key = "├ 󰧨 Login Manager";
                keyColor = "blue";
              }
              {
                type = "wmtheme";
                key = "├ 󰉼 WM Theme";
                keyColor = "blue";
              }
              {
                type = "theme";
                key = "├ 󰉼 Theme";
                keyColor = "blue";
              }
              {
                type = "icons";
                key = "├ 󰸉 Icons";
                keyColor = "blue";
              }
              {
                type = "font";
                key = "├ 󰛖 Font";
                keyColor = "blue";
              }
              {
                type = "terminal";
                key = "└ 󰆍 Terminal";
                keyColor = "blue";
              }
              "break"
              {
                type = "host";
                key = " 󰌢 Host";
                keyColor = "green";
              }
              {
                type = "cpu";
                key = "├ 󰘚 CPU";
                keyColor = "green";
                temp = true;
              }
              {
                type = "gpu";
                key = "├ 󰢮 GPU";
                keyColor = "green";
              }
              {
                type = "memory";
                key = "├ 󰍛 Memory";
                keyColor = "green";
              }
              {
                type = "disk";
                key = "├ 󰋊 Disk";
                keyColor = "green";
              }
              {
                type = "display";
                key = "└ 󰍹 Display";
                keyColor = "green";
              }
              "break"
              {
                type = "colors";
                symbol = "circle";
              }
            ];
          };
        };
        fd.enable = true;

        firefox = {
          enable = true;
          package = inputs."zen-browser".packages.${system}.zen-browser;
          configPath = ".mozilla/firefox";
          profiles.myuser = {
            isDefault = true;
            id = 0;
            settings = {
              "gfx.webrender.all" = true;
              "webgl.force-enabled" = true;
              "webgl.msaa-force" = true;
              "browser.backspace_action" = 0;
              "browser.download.alwaysOpenPanel" = false;
              "services.sync.prefs.sync.browser.uiCustomization.state" = true;
              "browser.sessionstore.restore_pinned_tabs_on_demand" = true;
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            };
            userChrome = builtins.readFile ../../dotfiles/firefox/firefox_userchrome.css;
          };
        };
        difftastic = {
          enable = true;
          git.enable = true;
        };
        git = {
          enable = true;
          signing = {
            format = "openpgp";
            key = "98BD7E80842C97BA";
            signByDefault = false;
          };
          settings = lib.mkForce [
            {
              user = {
                name = config.customGit.userName;
                email = config.customGit.userEmail;
              };
              checkout.defaultRemote = "origin";
              color = {
                diff = "auto";
                ui = true;
              };
              init.defaultBranch = "main";
              core.editor = "emacsclient --create-frame --alternate-editor ''";
              pull.rebase = false;
              push.autoSetupRemote = true;
              # credential.helper = "libsecret"; # Keep your existing system helper
              alias = {
                adog = "log --all --decorate --oneline --graph";
                plog = "log --all --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --branches";
                ignore-change = "update-index --assume-unchanged";
                unstage = "restore --staged";
                wt = "!git-worktree-cd";
              };

              credential = {
                "https://gitlab.com".helper = "!${pkgs.glab}/bin/glab auth git-credential";
                "https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
                "https://gist.github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
              };
            }

          ];
        };
        gh = {
          enable = true;
          extensions = [
            pkgs.gh-dash
            pkgs.gh-poi
            pkgs.gh-stack
          ];
          gitCredentialHelper.enable = true;
          settings.aliases = {
            web = "repo view --web";
          };
        };

        gpg.enable = true;

        ghostty = {
          enable = true;
          settings = {
            background-opacity = 0.85;
            bold-is-bright = true;
            clipboard-paste-protection = false;
            confirm-close-surface = true;
            copy-on-select = "clipboard";
            cursor-click-to-move = false;
            cursor-style = "block";
            cursor-style-blink = false;
            shell-integration-features = "no-cursor";
            term = "kitty";
            unfocused-split-opacity = 1.0;
            window-decoration = false;
            keybind = [
              "ctrl+shift+,=unbind"
              "ctrl+alt+shift+,=reload_config"
            ];
            # scrollbar = "system";
          };
        };

        hwatch.enable = true;

        jq = {
          enable = true;
        };

        jqp.enable = true;

        nix-init.enable = true;

        noctalia = lib.mkIf config.customPackages.gui.enable {
          enable = true;
          systemd.enable = false;
          # Upstream's critical-notification outline is 1px, invisible in practice.
          # Drop once noctalia makes the toast border width configurable.
          # package = pkgs.noctalia.overrideAttrs (prev: {
          #   postPatch = (prev.postPatch or "") + ''
          #     substituteInPlace src/shell/notification/notification_toast.cpp \
          #       --replace-fail "? Style::borderWidth : 0.0F" "? 1.0F : 0.0F"
          #   '';
          # });
          settings = {
            shell = {
              avatar_path = "${config.home.homeDirectory}/.face";
              show_location = true;
            };

            wallpaper = {
              enabled = true;
              directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
              fill_mode = "crop";
              transition_on_startup = false;
              automation.enabled = false;
            };

            theme = {
              mode = "auto";
              source = "wallpaper";
              wallpaper_scheme = "muted";
            };

            notification.enable_daemon = true;

            location = {
              auto_locate = true;
              address = "Copenhagen";
            };

            weather = {
              enabled = true;
              unit = "celsius";
              effects = true;
            };

            backdrop.enabled = false;

            bar.main = {
              position = "top";
              background_opacity = 0.0;
              radius = 12;
              margin_ends = 4;
              margin_edge = 0;
              padding = 2;
              widget_spacing = 6;
              scale = 1.0;
              reserve_space = true;
              capsule = true;
              capsule_opacity = 1.0;
              start = [
                "clock"
                "sysmon-cpu"
                "sysmon-ram"
                "active_window"
                "media"
              ];
              center = [ "group:mid" ];
              end = [ "group:right" ];
              capsule_group = [
                {
                  id = "mid";
                  members = [ "workspaces" ];
                  opacity = 1.0;
                  padding = 6.0;
                  radius = 12.0;
                }
                {
                  id = "right";
                  members = [
                    "tray"
                    "notifications"
                    "battery"
                    "input-volume"
                    "volume"
                    "brightness"
                    "bluetooth"
                    "control-center"
                    "session"
                  ];
                  opacity = 1.0;
                  padding = 6.0;
                  radius = 12.0;
                }
              ];
            };

            widget = {
              clock = {
                type = "clock";
                format = "{:%H:%M %d/%m/%y}";
              };
              sysmon-cpu = {
                type = "sysmon";
                stat = "cpu_usage";
              };
              sysmon-ram = {
                type = "sysmon";
                stat = "ram_used";
              };
            };
          };
        };

        rclone = {
          enable = true;
        };

        vicinae = {
          inherit (config.customPackages.gui) enable;
          package = pkgs.vicinae;
          systemd.enable = true;
          extensions = [
            inputs.vicinae-extensions.packages.x86_64-linux.niri-monitors
            (config.lib.vicinae.mkExtension {
              name = "nix-find";
              src = ../../dotfiles/vicinae/nix-find;
            })
          ];
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
                run-shell 'set -- $SSH_CLIENT; client_ip=$1; client_source_port=$2; ssh_server_port=$3; if [ -z "$client_ip" ]; then set -- $SSH_CONNECTION; client_ip=$1; client_source_port=$2; ssh_server_port=$4; fi; tmux set -g @tmux-net-client-host "$client_ip"; tmux set -g @tmux-net-client-source-port "$client_source_port"; tmux set -g @tmux-net-ssh-server-port "$ssh_server_port"; tmux set -g @tmux-net-timeout "1"'
                setw -g automatic-rename on
                setw -g automatic-rename-format "#(${tmuxWindowLabel}/bin/tmux-window-label '#{pane_current_path}' '#{pane_current_command}')"
                set -g @tmux-dotbar-session-text " #H "
                set -g status-left-length 80
                set -g @tmux-dotbar-status-left '#[bg=#0B0E14]#{?client_prefix,#[fg=#95E6CB]#[bg=#95E6CB]#[fg=#0B0E14]#[bold]#{?#{@tmux-net-client-host},󰌘 #H,#H}#[nobold]#[bg=#0B0E14]#[fg=#95E6CB],#[fg=#565B66] #{?#{@tmux-net-client-host},󰌘 #H,#H} }#[bg=#0B0E14]#[fg=#565B66]'
                set -g @tmux-dotbar-window-status-format " #W "
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

        starship = {
          enable = true;
          settings = builtins.fromTOML (builtins.readFile ../../dotfiles/starship/starship.toml);
        };

        keepassxc = {
          enable = true;
          autostart = false;
          package = pkgs.keepassxc;
        };

        fzf = {
          enable = true;
          enableBashIntegration = true;
          historyWidget.command = "";
          changeDirWidget = {
            options = [
              "--preview '${pkgs.eza}/bin/eza --tree --color=always \"{}\" | head -200'"
            ];
            command = "fd --type d";
          };
          fileWidget = {
            command = "fd --type file --hidden --no-ignore-vcs";
            options = [
              "--preview '${pkgs.bat}/bin/bat \"{}\" --style=changes,header-filename,numbers,snip,rule --paging always --force-colorization'"
            ];
          };
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

        ssh = {
          enable = true;
          enableDefaultConfig = false;
          includes = [ "~/.ssh/local_config" ];
          # extraOptionOverrides = lib.optionalAttrs config.customSsh.enableKeepassxc {
          #   ProxyCommand = "$HOME/.ssh/keepassxc-prompt %h %p";
          # };

          # settings."netbird-ssh-no-mux" = lib.hm.dag.entryBefore [ "*" ] {
          #   header = ''Match exec "${pkgs.netbird}/bin/netbird ssh detect %h %p"'';
          #   ControlMaster = "no";
          #   ControlPath = "none";
          #   ControlPersist = "no";
          # };

          settings."*" = {
            ForwardAgent = true;
            AddKeysToAgent = "yes";
            ControlMaster = "auto";
            ControlPath = "~/.ssh/sockets/%r@%h-%p";
            # Bounded, not "yes": a master whose netbird tunnel dies never notices
            # (ServerAlive* does not reap it through the ProxyCommand pipe), so an
            # infinite master stays broken forever. Expire instead.
            ControlPersist = "10m";
            ServerAliveInterval = 30;
            ServerAliveCountMax = 3;
          };
        };

        navi = {
          enable = true;
          settings.cheats.paths = [
            "${inputs.navi-cheats-src}"
            "${inputs.navi-tldr-pages-src}"
          ];
        };

        wallust = {
          enable = true;
        };

        nix-index-database.comma.enable = true;
        nix-index.enable = true;

        yazi = {
          enable = true;
          shellWrapperName = "y";
        };

        nh = {
          enable = true;
          flake = "${config.home.homeDirectory}/.config/home-manager";
        };

        nix-search-tv = {
          enable = true;
          settings = {
            update_interval = "12h";
          };
        };

        uv = {
          enable = true;
          settings = {
            python-preference = "managed";
          };
        };
      };

      # Home shell aliases
      home.shellAliases = {
        noctalia-restart = "pkill -x noctalia || true; noctalia --daemon";
        noctalia-reload = "noctalia msg config-reload";
        onefetch = "onefetch -E --nerd-fonts --no-color-palette";
        cat = "bat";
        watch = "hwatch";
        cdd = ''f(){ [ -d "$1" ] && cd "$1" || { [ -f "$1" ] && cd "$(dirname "$1")"; } || echo "No such file or directory"; }; f'';
        fm = "frogmouth";
        df = "duf --hide special";
        open = "xdg-open";
        nshell = ''f(){ [ $# -gt 0 ] || { echo "usage: nshell <package> [nix args...]" >&2; return 1; }; nix shell "nixpkgs#$1" "''${@:2}"; }; f'';
        venv = ''[ -n "$VIRTUAL_ENV" ] && deactivate; . .venv/bin/activate'';
        rsync = "rsync --info=progress2";
        plasma-restart = "systemctl restart --user plasma-plasmashell";
        dcup = "docker compose up --remove-orphans";
        dcview = "docker compose config | bat -l yml";
        dk = "dragon-drop --keep";
        dx = "dragon-drop --and-exit";
        ec = ''f(){ if [ -n "''${DISPLAY:-}''${WAYLAND_DISPLAY:-}" ]; then emacsclient --no-wait --reuse-frame --alternate-editor "" "$@"; else emacsclient -nw --alternate-editor "" "$@"; fi; }; f'';
        cx = "codex resume";
        grep = "grep --color=auto";
        q = "qalc";
        tldr = ''tldr_wrapper() { tldr "$1" || man "$1" | bat -l man -p; } && tldr_wrapper'';
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

      qt.enable = true;

      xdg = {
        configFile = {
          # The ghostty HM module writes the unit via xdg.configFile, which
          # bypasses HM's systemd handling, so its [Install] section is never
          # realised. Wire it up so the instance is warm before the first
          # Mod+Return instead of costing ~1.8s on the first launch.
          "systemd/user/graphical-session.target.wants/app-com.mitchellh.ghostty.service".source =
            "${config.programs.ghostty.package}/share/systemd/user/app-com.mitchellh.ghostty.service";
          "autostart/org.keepassxc.KeePassXC.desktop".text = ''
            [Desktop Entry]
            Name=KeePassXC
            Exec=keepassxc
            TryExec=keepassxc
            Icon=keepassxc
            StartupNotify=false
            Terminal=false
            Type=Application
            Version=1.5
            X-GNOME-Autostart-enabled=true
          '';
        };
        dataFile = {
          "applications/org.keepassxc.KeePassXC.desktop".text = ''
            [Desktop Entry]
            Name=KeePassXC
            GenericName=Password Manager
            Comment=Community-driven port of KeePass Password Safe
            Exec=keepassxc %f
            TryExec=keepassxc
            Icon=keepassxc
            StartupWMClass=keepassxc
            StartupNotify=false
            Terminal=false
            Type=Application
            Version=1.5
            Categories=Utility;Security;Qt;
            MimeType=application/x-keepass2;
            SingleMainWindow=true
            X-GNOME-SingleWindow=true
            Keywords=security;privacy;password-manager;yubikey;password;keepass;
          '';
        };
        mimeApps = {
          enable = true;
          defaultApplications = {
            "application/x-directory" = [ "org.kde.dolphin.desktop" ];
            "application/xhtml+xml" = [ "zen.desktop" ];
            "inode/directory" = [ "org.kde.dolphin.desktop" ];
            "text/html" = [ "zen.desktop" ];
            "x-scheme-handler/file" = [ "org.kde.dolphin.desktop" ];
            "x-scheme-handler/http" = [ "zen.desktop" ];
            "x-scheme-handler/https" = [ "zen.desktop" ];
          };
        };
        terminal-exec = {
          enable = true;
          settings.default = [ "com.mitchellh.ghostty.desktop" ];
        };
        autostart = {
          enable = true;
          entries = [ "${pkgs.netbird-ui}/share/applications/netbird.desktop" ];
        };
      };

    };
}
