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
  };

  config = {
    programs = {
      bash = {
        enable = true;
        profileExtra = builtins.readFile ../../dotfiles/bash/.profile;
        initExtra = "";
        bashrcExtra = ''
          if [[ $TERM = dumb ]]; then
              return
          fi

          if [[ -z "$SSH_CONNECTION" ]]; then
              ${pkgs.coreutils}/bin/cat ${config.xdg.cacheHome}/wal/sequences
          fi
          ${builtins.readFile ../../bin/secret-export}

          shopt -s cdspell
          eval "$(batman --export-env)"
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
        package = pkgs.emacs30-gtk3;
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

      git = {
        enable = true;
        signing = {
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

      ghostty = {
        enable = true;
        settings = {
          bold-is-bright = true;
          background-opacity = 0.85;
          window-decoration = false;

          clipboard-paste-protection = false;
          confirm-close-surface = false;
          copy-on-select = "clipboard";
          cursor-style = "block";
          cursor-style-blink = false;
          shell-integration-features = "no-cursor";
          term = "kitty";
          unfocused-split-opacity = 1.0;
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
        mounts = {
          "dropbox-private" = {
            remote = "dropbox-private";
            mountPoint = "~/dropbox-private";
            extraArgs = [
              "--vfs-cache-mode=full"
              "--vfs-cache-max-size=10G"
              "--vfs-cache-max-age=6h"
              "--dir-cache-time=3h"
              "--attr-timeout=1h"
              "--buffer-size=32M"
              "--vfs-fast-fingerprint"
            ];
          };
          "onedrive-ku" = {
            remote = "onedrive-ku";
            mountPoint = "~/onedrive-ku";
            extraArgs = [
              "--vfs-cache-mode=full"
              "--vfs-cache-max-size=10G"
              "--vfs-cache-max-age=6h"
              "--dir-cache-time=3h"
              "--attr-timeout=1h"
              "--buffer-size=32M"
              "--vfs-fast-fingerprint"
            ];
          };
          "onedrive-ku-crypt" = {
            remote = "onedrive-ku-crypt";
            mountPoint = "~/onedrive-ku-crypt";
            extraArgs = [
              "--vfs-cache-mode=off"
              "--dir-cache-time=3h"
              "--attr-timeout=1h"
              "--buffer-size=32M"
              "--vfs-fast-fingerprint"
            ];
          };
        };
      };

      tmux = {
        enable = true;
        newSession = true;
        clock24 = true;
        baseIndex = 1;
        escapeTime = 1;
        terminal = "xterm-256color";
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

      fastfetch = {
        enable = true;
      };

      fzf = {
        enable = true;
        enableBashIntegration = true;
        changeDirWidgetOptions = [
          "--preview '${pkgs.eza}/bin/eza --tree --color=always {} | head -200'"
        ];
        changeDirWidgetCommand = "fd --type d";
        fileWidgetCommand = "fd --type f --hidden";
        fileWidgetOptions = [
          "--preview '${pkgs.bat}/bin/bat --style=changes,header-filename,snip,rule --paging always --force-colorization {}'"
        ];
      };

      bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras; [ batman ];
        config = {
          map-syntax = [
            "*.conf:TOML"
            "*.gdextension:TOML"
            "u2f_keys:CSV"
          ];
        };
      };

      readline = {
        enable = true;
        extraConfig = ''
          $include /etc/inputrc

          set completion-ignore-case On
          set completion-prefix-display-length 3
          set mark-symlinked-directories On
          set show-all-if-ambiguous On
          set show-all-if-unmodified On
        '';
      };

      ssh = {
        matchBlocks."*".forwardAgent = true;
      };

      navi = {
        enable = true;
        enableBashIntegration = true;
      };

      nix-index = {
        enable = true;
        enableBashIntegration = true;
      };
      nix-search-tv.enable = true;

      uv = {
        enable = true;
        settings = {
          python-preference = "managed";
        };
      };
    };

    # Home shell aliases
    home.shellAliases = {
      nb-peers = ''get-peers() { command "$1" status --json | ${pkgs.jq}/bin/jq ".peers.details.[] | {fqdn, netbirdIp, status, connectionType}" -r}; get-peers'';
      onefetch = "onefetch -E --nerd-fonts --no-color-palette";
      cat = "bat";
      watch = "hwatch";
      cdd = ''f(){ [ -d "$1" ] && cd "$1" || { [ -f "$1" ] && cd "$(dirname "$1")"; } || echo "No such file or directory"; }; f'';
      fm = "frogmouth";
      db = "distrobox";
      df = "duf --hide special";
      open = "xdg-open";
      nproc-1 = "$(( $(nproc) - 1))";
      venv = ''[ -n "$VIRTUAL_ENV" ] && deactivate; . .venv/bin/activate'';
      rsync = "rsync --info=progress2";
      plasma-restart = "systemctl restart --user plasma-plasmashell";
      dcup = "docker compose up --remove-orphans";
      dcview = "docker compose config | bat -l yml";
      dk = "dragon --keep";
      dx = "dragon --and-exit";
      ec = ''emacsclient --no-wait --reuse-frame --alternate-editor ""'';
      grep = "grep --color=auto";
      q = "qalc";
      tldr = ''tldr_wrapper() { tldr "$1" || man "$1" | bat -l man -p; } && tldr_wrapper'';
    };

    nix = {
      package = pkgs.nix;
      settings = {
        substituters = [ "https://cache.nixos.org/" ];
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
      terminal-exec = {
        enable = true;
        settings.default = [ "net.local.ghostty.desktop" ];
      };
      autostart = {
        enable = true;
        entries = [ "${pkgs.netbird-ui}/share/applications/netbird.desktop" ];
      };
    };
  };
}
