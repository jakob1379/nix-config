{
  config,
  pkgs,
  inputs,
  system,
  lib,
  ...
}:
let
  tmuxPing = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-ping";
    version = "unstable-2024-08-01";
    src = pkgs.fetchFromGitHub {
      owner = "ayzenquwe";
      repo = "tmux-ping";
      rev = "853175737b5af4b6d00ba5d18e3e059c9a7e3973";
      sha256 = "0vflnfjczd21hsr3nvmgdp41qi0bcyj0m2z8lrdcgf11j9y99gsa";
    };
    rtpFilePath = "ping.tmux";
  };
in
{
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
          initExtra = ''
            bind '"\C-w": "nix-find\n"'
            bind '"\ea": "ag-fuzzy\n"'
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

        distrobox = {
          enable = true;
          containers = {
            ubuntu25 = {
              image = "ubuntu:24.04"; # Specify your desired image here
              init_hooks = "curl -LsSf https://astral.sh/uv/install.sh | sh";
              additional_packages = "curl"; # Additional packages needed for init_hooks
              entry = true; # Make this container enterable by default (optional)
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
          package = pkgs.emacs-pgtk;
        };

        fastfetch = {
          enable = true;
        };

        fd.enable = true;

        firefox = {
          enable = true;
          package = inputs."zen-browser".packages.${system}.zen-browser;
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
          settings = {
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
            pull.rebase = false;
            push.autoSetupRemote = true;
            credential.helper = "libsecret";
            alias = {
              adog = "log --all --decorate --oneline --graph";
              plog = "log --all --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --branches";
              ignore-change = "update-index --assume-unchanged";
              prune-deep = ''
                              !f() {
                	        git fetch --prune;
                	        current=$(git symbolic-ref --short HEAD 2>/dev/null || echo "");
                	        # Branches whose upstream is gone are marked [gone] by -vv
                	        branches=$(git branch -vv | awk '/\[gone\]/{print $1}');
                	        # Optionally protect some branches
                	        protect="main master develop $current";
                	        filtered="";
                	        for b in $branches; do
                	          skip=0;
                	          for p in $protect; do [ "$b" = "$p" ] && skip=1 && break; done;
                	          [ $skip -eq 0 ] && filtered="$filtered $b";
                	        done;
                	        filtered=$(echo $filtered);
                	        if [ -z "$filtered" ]; then
                	          echo "No local branches with gone upstreams.";
                	          exit 0;
                	        fi;
                	        echo "Branches with gone upstreams:";
                	        for b in $filtered; do echo "  $b"; done;
                	        printf "Delete these branches? (y/N): ";
                	        read confirm;
                	        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                	          # Use -d to be safe; change to -D if you want force
                	          for b in $filtered; do git branch -d "$b" || true; done;
                	        else
                	          echo "No branches were deleted.";
                	        fi;
                	            }; f'';
              unstage = "restore --staged";
            };
          };
        };
        gh = {
          enable = true;
          extensions = [ pkgs.gh-dash ];
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
            confirm-close-surface = false;
            copy-on-select = "clipboard";
            cursor-style = "block";
            cursor-style-blink = false;
            shell-integration-features = "no-cursor";
            term = "kitty";
            unfocused-split-opacity = 1.0;
            window-decoration = false;
            # scrollbar = "system";
          };
        };

        hwatch.enable = true;

        jq = {
          enable = true;
        };

        jqp.enable = true;

        nix-init.enable = true;

        # niriswitcher = {
        #   enable = true;
        #   package = pkgs.niriswitcher;
        #   settings = {
        #     keys = {
        #       modifier = "Super";
        #       switch = {
        #         next = "Tab";
        #         prev = "Shift+Tab";
        #       };
        #       window = {
        #         abort = "Escape";
        #       };
        #     };
        #     center_on_focus = true;
        #   };
        # };

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
          plugins = [ tmuxPing ];
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

        keepassxc = {
          enable = true;
          autostart = false;
          package = pkgs.keepassxc;
        };

        ranger = {
          enable = true;
          extraPackages = with pkgs; [
            python3Packages.pillow
          ];
          settings = {
            preview_images = true;
            preview_images_method = "kitty";
          };
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
              "_.conf:TOML"
              "_.gdextension:TOML"
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
        };

        wallust = {
          enable = true;
        };

        opencode = {
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
                  "gpt-5.4" = {
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

            model = "openai/gpt-5.4";
            small_model = "openai/gpt-5.3-codex";

            plugin = [
              "file://${config.home.homeDirectory}/.config/opencode/node_modules/oh-my-opencode-slim/dist/index.js"
              "@mohak34/opencode-notifier@latest"
              "@franlol/opencode-md-table-formatter@latest"
              "@inkdust2021/opencode-vibeguard@latest"
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
            keybinds = {
              app_exit = "ctrl+shift+q";
              input_clear = "ctrl+c";
            };
          };
        };

        nix-index = {
          enable = true;
          enableBashIntegration = true;
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
        noctalia-restart = ''"noctalia-shell list --all --json | jq .[].pid | xargs kill || echo "No instances to kill, starting new" && noctalia-shell -d"'';
        onefetch = "onefetch -E --nerd-fonts --no-color-palette";
        cat = "bat";
        watch = "hwatch";
        cdd = ''f(){ [ -d "$1" ] && cd "$1" || { [ -f "$1" ] && cd "$(dirname "$1")"; } || echo "No such file or directory"; }; f'';
        fm = "frogmouth";
        db = "distrobox";
        df = "duf --hide special";
        open = "xdg-open";
        nshell = ''f(){ [ $# -gt 0 ] || { echo "usage: nshell <package> [nix args...]" >&2; return 1; }; nix shell --set-env-var OMP_NIX_SHELL 1 "nixpkgs#$1" "''${@:2}"; }; f'';
        nproc-1 = "$(( $(nproc) - 1))";
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
          "opencode/oh-my-opencode-slim.json".source = config.lib.file.mkOutOfStoreSymlink (
            config.home.homeDirectory + "/.config/home-manager/dotfiles/opencode/oh-my-opencode-slim.json"
          );
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
        }
        // lib.optionalAttrs config.customPackages.gui.enable {
          "vicinae/scripts/display-mode-picker" = {
            executable = true;
            text = ''
              #!/usr/bin/env bash
              # @vicinae.schemaVersion 1
              # @vicinae.title Display Mode Picker
              # @vicinae.mode compact
              # @vicinae.keywords ["display", "monitor", "screen", "layout"]
              exec display-mode-picker "$@"
            '';
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
