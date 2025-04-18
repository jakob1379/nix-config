{
  inputs,
  config,
  system,
  pkgs,
  ...
}:
let
  flakePath = "${config.xdg.configHome}/home-manager";
in
{
  programs = {
    bash = {
      enable = true;
      profileExtra = builtins.readFile ./dotfiles/bash/.profile;

      bashrcExtra = ''
        # ------------------ extra start ------------------
        if [[ $TERM = dumb ]]; then
            return
        fi

        if [[ -z "$SSH_CONNECTION" ]]; then
            ${pkgs.coreutils}/bin/cat ${config.xdg.cacheHome}/wal/sequences
        fi
        ${builtins.readFile ./bin/secret-export.sh}

        # ------------------ extra end ------------------
      '';
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
      extraConfig = builtins.readFile ./dotfiles/tmux/tmux.conf;
    };

    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    readline = {
      enable = true;
      extraConfig = ''
        # Include the system-wide settings from /etc/inputrc
        $include /etc/inputrc

        # Enable case-insensitive completion (e.g., 'foo' will match 'Foo' and 'FOO')
        # Example: Typing 'ls foo' will match 'Foo.txt', 'foo.txt', and 'FOO.txt'
        set completion-ignore-case On

        # Set the minimum number of characters to display prefix matches during completion
        # Example: tabbing will show this
        # $ cat .bash
        #  ..._history  ..._logout
        # very useful for long filenames!
        set completion-prefix-display-length 3

        # Mark directories that are symlinked with a trailing slash
        # Example: If 'mydir' is a symlink to a directory, typing 'ls mydir' will display 'mydir/' to indicate it's a directory
        set mark-symlinked-directories On

        # Show all possible completions when the input is ambiguous (e.g., multiple matches)
        # Example: Typing 'ls f' when there are 'foo.txt' and 'file.txt' will immediately list both options
        set show-all-if-ambiguous On

        # Show all possible completions even if the input is not modified after the first attempt
        # Example: If you press Tab and there are multiple completions, pressing Tab again without typing more will show all options
        set show-all-if-unmodified On
      '';
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
    };

    firefox = {
      enable = true;
      package = inputs."zen-browser".packages.${system}.zen-browser;
      profiles = {
        myuser = {
          isDefault = true;
          id = 0;
          # extensions = with inputs.firefox-addons.packages.${pkgs.system}; [ ublock-origin bitwarden ];
          settings = {
            # WebGL configs
            "gfx.webrender.all" = true;
            "webgl.force-enabled" = true;
            "webgl.msaa-force" = true;

            # backspace should to back to previous page
            "browser.backspace_action" = 0;

            # Enable css to hide tab bar
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

            # Don't auto open download panel
            "browser.download.alwaysOpenPanel" = false;

            # backup ui layout
            "services.sync.prefs.sync.browser.uiCustomization.state" = true;

            # ensure pinned tabs are not loaded during start
            "browser.sessionstore.restore_pinned_tabs_on_demand" = true;
          };
          userChrome = builtins.readFile ./dotfiles/firefox/firefox_userchrome.css;
        };
      };
    };

    oh-my-posh = {
      enable = true;
      enableBashIntegration = true;
      settings = builtins.fromJSON (builtins.readFile ./dotfiles/oh-my-posh/custom-hunks-theme.omp.json);
    };

    git = {
      enable = true;
      userName = "Jakob Guldberg Aaes";
      userEmail = "jakob1379@gmail.com";
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
        plog = "log  --all --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --branches";
        ignore-change = "update-index --assume-unchanged";
        prune-deep = ''!git fetch --prune; branches=$(git branch -r | awk '"'"'{print $1}'"'"' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '"'"'{print $1}'"'"'); echo -e "branches:\n$branches"; read -p "Do you want to delete all these branches? (y/n): " confirm; if [ "$confirm" = "y" ]; then echo "$branches" | xargs git branch -d; else echo "No branches were deleted"; fi'';
        unstage = "restore --staged";
      };
    };

    gh.enable = true;

    fastfetch.enable = true;
    nix-index = {
      enable = true;
      enableBashIntegration = false;
    };

    emacs = {
      enable = true;
      package = pkgs.emacs30-gtk3;
      extraPackages = epkgs: [ ];
    };

    ssh.forwardAgent = true;

    fzf = {
      enable = true;
      enableBashIntegration = true;
      changeDirWidgetOptions = [
        "--preview '${pkgs.eza}/bin/eza --tree --color=always {} | head -200'"
      ];
      changeDirWidgetCommand = "fd --type d";
      fileWidgetCommand = "fd --type f";
      fileWidgetOptions = [
        "--preview '${pkgs.bat}/bin/bat -Pf {}'"
      ];
    };

    bat = {
      enable = true;
      config = {
        map-syntax = [ "*.conf:TOML" ];
      };
    };

    poetry = {
      enable = true;
      settings = {

        virtualenvs.create = false;
        virtualenvs.in-project = true;
      };
    };
  };

  nix = {
    package = pkgs.nix;
    settings = {
      max-jobs = 1;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  home.shellAliases = {
    netbird-peers = ''netbird status --json | jq ".peers.details.[] | {fqdn, netbirdIp, status, connectionType}" -r'';
    onefetch = "onefetch -E --nerd-fonts --no-color-palette";
    cat = "bat";
    fm = "frogmouth";
    df = "duf --hide special";
    open = "xdg-open";
    venv = ''[ -n "$VIRTUAL_ENV" ] && deactivate; . .venv/bin/activate'';
    rsync = "rsync --info=progress2";

    # docker
    dcup = "docker compose up --remove-orphans";
    dcview = "docker compose config | bat -l yml";

    # dragon
    dk = "dragon --keep";
    dx = "dragon --and-exit";

    # EDA
    eda = "nix-shell -p python313Packages.rich python313Packages.ipython python313Packages.pandas python313Packages.seaborn python313Packages.plotly";

    ec = ''emacsclient --no-wait --reuse-frame --alternate-editor ""'';
    grep = "grep --color=auto";

    # home-manager and nix update and switch
    hs = ''f(){ home-manager switch "$@" |& "${pkgs.nix-output-monitor}/bin/nom"; }; f'';
    hsu = ''f(){ home-manager switch "$@" |& "${pkgs.nix-output-monitor}/bin/nom"; }; nix flake update --flake ${flakePath} && f'';
    ns = ''f(){ sudo nixos-rebuild switch --flake ${flakePath} |& "${pkgs.nix-output-monitor}/bin/nom"; }; f'';
    nsu = ''f(){ sudo nixos-rebuild switch --flake ${flakePath} |& "${pkgs.nix-output-monitor}/bin/nom"; }; sudo nix-channel --update && f'';

    updateAll = ''
      f() {
        nix flake update --flake ${flakePath}
        nix-channel --update
        home-manager switch "$@" |& "${pkgs.nix-output-monitor}/bin/nom"
        sudo nixos-rebuild switch --flake ${flakePath} |& "${pkgs.nix-output-monitor}/bin/nom"
      };
      f
    '';

    q = "qalc";
    tldr = ''tldr_wrapper() { tldr "$1" || man "$1" | bat -l man -p; } && tldr_wrapper'';
  };
}
