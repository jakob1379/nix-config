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
      opencodeMainModel = "openai/gpt-5.5";
      opencodeSmallModel = "openai/gpt-5.5";
      opencodeSlimSettings = {
        "$schema" = "https://unpkg.com/oh-my-opencode-slim@latest/oh-my-opencode-slim.schema.json";
        autoUpdate = true;
        preset = "openai";
        presets = {
          openai = {
            orchestrator = {
              model = opencodeMainModel;
              variant = "high";
              skills = [ "*" ];
              mcps = [
                "*"
                "!context7"
              ];
            };
            oracle = {
              model = opencodeMainModel;
              variant = "high";
              skills = [ "simplify" ];
              mcps = [ ];
            };
            librarian = {
              model = opencodeSmallModel;
              variant = "low";
              skills = [ ];
              mcps = [
                "websearch"
                "context7"
                "grep_app"
              ];
            };
            explorer = {
              model = opencodeSmallModel;
              variant = "low";
              skills = [ ];
              mcps = [ ];
            };
            designer = {
              model = opencodeSmallModel;
              variant = "medium";
              skills = [ "agent-browser" ];
              mcps = [ ];
            };
            fixer = {
              model = opencodeSmallModel;
              variant = "low";
              skills = [ ];
              mcps = [ ];
            };
          };
        };
      };
      sshSocketDir = config.home.homeDirectory + "/.ssh/sockets";
    in
    {
      home = {
        packages = [ pkgs.agent-browser ];
        shell.enableBashIntegration = true;
        activation.ensureSshSocketsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${pkgs.coreutils}/bin/mkdir -p "${sshSocketDir}"
          ${pkgs.coreutils}/bin/chmod 700 "${config.home.homeDirectory}/.ssh"
          ${pkgs.coreutils}/bin/chmod 700 "${sshSocketDir}"
        '';

        file = lib.optionalAttrs config.customSsh.enableKeepassxc {
          ".ssh/keepassxc-prompt".source = ../../scripts/ssh/keepassxc-prompt.sh;
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
          '';
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

            eval "$(batman --export-env)"
            eval "$(command up --init bash)"
            source <(command git-worktree-cd --init bash)
          '';
        };

        direnv = {
          enable = true;
          enableBashIntegration = true;
          nix-direnv.enable = true;
        };

        emacs = {
          enable = true;
          package = pkgs.emacs-pgtk;
        };

        fastfetch = {
          enable = true;
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

        rclone = {
          enable = true;
        };

        vicinae = {
          inherit (config.customPackages.gui) enable;
          package = pkgs.vicinae;
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
                setw -g automatic-rename on
                setw -g automatic-rename-format "#(${tmuxWindowLabel}/bin/tmux-window-label '#{pane_current_path}' '#{pane_current_command}')"
                set -g @tmux-dotbar-session-text " #H "
                set -g status-left-length 80
                set -g @tmux-dotbar-status-left '#[bg=#0B0E14]#{?client_prefix,#[fg=#95E6CB]#[bg=#95E6CB]#[fg=#0B0E14]#[bold]#H#[nobold]#[bg=#0B0E14]#[fg=#95E6CB],#[fg=#565B66] #H }#[bg=#0B0E14]#[fg=#565B66]'
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

        oh-my-posh = {
          enable = true;
          settings = builtins.fromJSON (builtins.readFile ../../dotfiles/oh-my-posh/new-theme.json);
        };

        keepassxc = {
          enable = true;
          autostart = false;
          package = pkgs.keepassxc;
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

        ssh = {
          enable = true;
          enableDefaultConfig = false;
          includes = [ "~/.ssh/local_config" ];
          # extraOptionOverrides = lib.optionalAttrs config.customSsh.enableKeepassxc {
          #   ProxyCommand = "$HOME/.ssh/keepassxc-prompt %h %p";
          # };

          settings."netbird-ssh-no-mux" = lib.hm.dag.entryBefore [ "*" ] {
            header = ''Match exec "${pkgs.netbird}/bin/netbird ssh detect %h %p"'';
            ControlMaster = "no";
            ControlPath = "none";
            ControlPersist = "no";
          };

          matchBlocks = {
            "*" = {
              forwardAgent = true;
              addKeysToAgent = "yes";
              controlMaster = "auto";
              controlPath = "~/.ssh/sockets/%r@%h-%p";
              controlPersist = "yes";
              serverAliveInterval = 30;
              serverAliveCountMax = 3;
            };
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

        wallust = {
          enable = true;
        };

        opencode = {
          commands = {
            desloppify = builtins.readFile ../../dotfiles/opencode/commands/desloppify.md;
          };

          enable = true;
          settings = {
            lsp = {
              markdown = {
                extensions = [ ".md" ];
                command = [
                  "nix"
                  "run"
                  "nixpkgs#marksman"
                  "--"
                  "server"
                ];
              };

              nixd = {
                extensions = [ ".nix" ];
                command = [
                  "nix"
                  "run"
                  "nixpkgs#nixd"
                  "--"
                ];
              };

              gopls = {
                extensions = [ ".go" ];
                command = [
                  "nix"
                  "run"
                  "nixpkgs#gopls"
                  "--"
                ];
              };

              rust = {
                extensions = [ ".rs" ];
                command = [
                  "nix"
                  "run"
                  "nixpkgs#rust-analyzer"
                  "--"
                ];
              };

              pyright = {
                disabled = true;
              };

              ruff = {
                command = [
                  "uv"
                  "run"
                  "--with"
                  "ruff"
                  "ruff"
                  "server"
                ];
                extensions = [
                  ".py"
                  ".pyi"
                ];
              };

              ty = {
                command = [
                  "uv"
                  "run"
                  "--with"
                  "ty"
                  "ty"
                  "server"
                ];
                extensions = [
                  ".py"
                  ".pyi"
                ];
              };
            };

            mcp = {
              context7 = {
                type = "remote";
                url = "https://mcp.context7.com/mcp";
                enabled = true;
              };
            };

            provider = {
              deepseek = {
                options = {
                  apiKey = "{env:DEEPSEEK_API_KEY}";
                  baseURL = "https://api.deepseek.com/v1";
                };
              };

              openai = {
                models = {
                  "gpt-5.5" = {
                    options = {
                      reasoningEffort = "high";
                    };
                    variants = {
                      low = {
                        reasoningEffort = "low";
                      };
                      high = {
                        reasoningEffort = "high";
                      };
                      xhigh = {
                        reasoningEffort = "xhigh";
                      };
                    };
                  };
                };
              };
            };

            model = opencodeMainModel;
            small_model = opencodeSmallModel;

            plugin = [
              "oh-my-opencode-slim@latest"
              "@mohak34/opencode-notifier@latest"
              "@franlol/opencode-md-table-formatter@latest"
              "opencode-devcontainers"
            ];

            agent = {
              explore = {
                disable = true;
              };
              general = {
                disable = true;
              };
            };
          };

          tui = {
            plugin = [ "oh-my-opencode-slim@latest" ];
            keybinds = {
              app_exit = "ctrl+shift+q";
              input_clear = "ctrl+c";
            };
          };
        };

        nix-index-database.comma.enable = true;
        nix-index.enable = true;

        yazi = {
          enable = true;
          shellWrapperName = "y";
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
        noctalia-restart = "noctalia-shell list --all --json | jq -Rsc '(fromjson? // [])[]?.pid' | xargs -r kill; noctalia-shell -d";
        onefetch = "onefetch -E --nerd-fonts --no-color-palette";
        cat = "bat";
        watch = "hwatch";
        cdd = ''f(){ [ -d "$1" ] && cd "$1" || { [ -f "$1" ] && cd "$(dirname "$1")"; } || echo "No such file or directory"; }; f'';
        fm = "frogmouth";
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
          "opencode/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink (
            config.home.homeDirectory + "/.config/home-manager/dotfiles/AGENTS.md"
          );
          "opencode/oh-my-opencode-slim.json".text = builtins.toJSON opencodeSlimSettings;
          "opencode/skills/agent-browser".source = "${inputs.agent-browser-src}/skills/agent-browser";
          "opencode/skills/codemap".source = "${inputs.oh-my-opencode-slim-src}/src/skills/codemap";
          "opencode/skills/simplify".source = "${inputs.oh-my-opencode-slim-src}/src/skills/simplify";
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
