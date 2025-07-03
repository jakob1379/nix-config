{
  config,
  pkgs,
  inputs,
  system,
  lib,
  ...
}:

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
        bashrcExtra = ''
          if [[ $TERM = dumb ]]; then
              return
          fi

          if [[ -z "$SSH_CONNECTION" ]]; then
              ${pkgs.coreutils}/bin/cat ${config.xdg.cacheHome}/wal/sequences
          fi
          ${builtins.readFile ../../bin/secret-export.sh}
        '';
      };

      git = {
        enable = true;
        inherit (config.customGit) userName;
        inherit (config.customGit) userEmail;
        signing = {
          key = "98BD7E80842C97BA";
          signByDefault = false;
        };
        extraConfig = {
          push.autoSetupRemote = true;
          pull.rebase = false;
          init.defaultBranch = "main";
          color.ui = true;
          color.diff = "auto";
        };
        aliases = {
          adog = "log --all --decorate --oneline --graph";
          plog = "log --all --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --branches";
          ignore-change = "update-index --assume-unchanged";
          prune-deep = ''!git fetch --prune; branches=$(git branch -r | awk '"'"'{print $1}'"'"' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '"'"'{print $1}'"'"'); echo -e "branches:\n$branches"; read -p "Do you want to delete all these branches? (y/n): " confirm; if [ "$confirm" = "y" ]; then echo "$branches" | xargs git branch -d; else echo "No branches were deleted"; fi'';
          unstage = "restore --staged";
        };
      };

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
      hwatch.enable = true;

      emacs = {
        enable = true;
        package = pkgs.emacs30-gtk3;
      };
      ghostty = {
        enable = true;
        settings = {
          bold-is-bright = true;
          background-opacity = 0.9;
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
      };

      direnv = {
        enable = true;
        enableBashIntegration = true;
        nix-direnv.enable = true;
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

      gh = {
        enable = true;
        extensions = [ pkgs.gh-dash ];
        settings.aliases = {
          web = "repo view --web";
        };
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
        fileWidgetCommand = "fd --type f";
        fileWidgetOptions = [ "--preview '${pkgs.bat}/bin/bat -Pf {}'" ];
      };

      bat = {
        enable = true;
        config = {
          map-syntax = [
            "*.conf:TOML"
            "*.gdextension:TOML"
          ];
        };
      };

      poetry = {
        enable = true;
        settings = {
          virtualenvs.create = false;
          virtualenvs.in-project = true;
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
        forwardAgent = true;
      };

      navi = {
        enable = true;
        enableBashIntegration = true;
      };

      nix-index = {
        enable = true;
        enableBashIntegration = false;
      };
    };

    # Home shell aliases
    home.shellAliases =
      let
        flakePath = "${config.xdg.configHome}/home-manager";
      in
      {
        netbird-peers = ''netbird status --json | jq ".peers.details.[] | {fqdn, netbirdIp, status, connectionType}" -r'';
        onefetch = "onefetch -E --nerd-fonts --no-color-palette";
        cat = "bat";
        watch = "hwatch";
        cdd = ''f(){ [ -d "$1" ] && cd "$1" || { [ -f "$1" ] && cd "$(dirname "$1")"; } || echo "No such file or directory"; }; f'';
        fm = "frogmouth";
        df = "duf --hide special";
        open = "xdg-open";
        venv = ''[ -n "$VIRTUAL_ENV" ] && deactivate; . .venv/bin/activate'';
        rsync = "rsync --info=progress2";
        plasma-restart = "systemctl restart --user plasma-plasmashell";
        dcup = "docker compose up --remove-orphans";
        dcview = "docker compose config | bat -l yml";
        dk = "dragon --keep";
        dx = "dragon --and-exit";
        eda = "nix-shell -p python313Packages.rich python313Packages.ipython python313Packages.pandas python313Packages.seaborn python313Packages.plotly";
        ec = ''emacsclient --no-wait --reuse-frame --alternate-editor ""'';
        grep = "grep --color=auto";
        hs = ''f(){ home-manager switch --flake ${flakePath} "$@" |& "${pkgs.nix-output-monitor}/bin/nom"; }; f'';
        hsu = ''f(){ nix flake update --flake ${flakePath} && home-manager switch --flake ${flakePath} "$@" |& "${pkgs.nix-output-monitor}/bin/nom"; }; f'';
        ns = ''f(){ sudo nixos-rebuild switch --flake ${flakePath} |& "${pkgs.nix-output-monitor}/bin/nom"; }; f'';
        nsu = ''f(){ sudo nix-channel --update && sudo nixos-rebuild switch --flake ${flakePath} |& "${pkgs.nix-output-monitor}/bin/nom"; }; f'';
        updateAll = ''
          f() {
            nix flake update --flake ${flakePath}
            nix-channel --update
            home-manager switch --flake ${flakePath} "$@" |& "${pkgs.nix-output-monitor}/bin/nom"
            sudo nixos-rebuild switch --flake ${flakePath} |& "${pkgs.nix-output-monitor}/bin/nom"
          };
          f
        '';
        q = "qalc";
        tldr = ''tldr_wrapper() { tldr "$1" || man "$1" | bat -l man -p; } && tldr_wrapper'';
      };

    # Nix configuration
    nix = {
      package = pkgs.nix;
      settings = {
        max-jobs = 1;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
      gc = {
        automatic = true;
        frequency = "weekly";
        options = "--delete-older-than 2w";
      };
    };
  };
}
