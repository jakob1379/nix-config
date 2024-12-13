{ config, pkgs, ... }:

{
  programs = {
    atuin = {
      enable = true;
      enableBashIntegration = true;
      flags = [ "--disable-up-arrow" ];
    };

    bash = {
      enable = true;
      profileExtra = ''
        # Auto-start tmux for remote SSH sessions if the shell is interactive
        if [ -z "$INSIDE_EMACS" ]; then
          # If it's a TRAMP connection (TERM is "dumb"), do not proceed with tmux
          if [ "$TERM" = "dumb" ]; then
            PS1="> "
          else
            if [ -z "$TMUX" ] && [ -n "$PS1" ] && [ "$TERM" != "dumb" ]; then
              tmux attach || tmux new || echo "Unable to start or attach to tmux session."
            fi
          fi
        fi
      '';
      
      bashrcExtra = ''
      if [[ $TERM = dumb ]]; then
          return
      fi

      ${builtins.readFile ./bin/secret-export}
      '';
    };

    thefuck.enable = true;
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

    emacs = {
      enable = true;
      package = pkgs.emacs-gtk;
    };
    ssh.forwardAgent = true;

    fzf = {
      enable = true;
      enableBashIntegration = true;
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
      max-jobs = "auto";
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  home.shellAliases = {
    cdd = ''f(){ [ -d "$1" ] && cd "$1" || { [ -f "$1" ] && cd "$(dirname "$1")"; } || echo "No such file or directory"; }; f'';

    # docker
    dcup = "docker compose up --remove-orphans";
    dcview = "docker compose config | bat -l yml";

    # dragon
    dk = "dragon --keep";
    dx = "dragon --and-exit";

    # eda
    eda = "nix-shell -p python313Packages.beautifulsoup python313Packages.requests python313Packages.rich python313Packages.ipython python313Packages.pandas python313Packages.seaborn python313Packages.plotly";

    ec = "emacsclient -n";
    grep = "grep --color=auto";

    # nix update and switch
    # Update and switch Home Manager
    updateHome = ''
      nix flake update --flake ~/.config/home-manager && \
      home-manager switch
    '';

    # clean netbird token
    netbird-logout = ''
      netbird down
      sudo cat /var/lib/netbird/config.json | jq 'del(.PrivateKey)' | sudo tee /var/lib/netbird/tmp-config.json > /dev/null && \
      sudo mv /var/lib/netbird/tmp-config.json /var/lib/netbird/config.json
    '';

    # Update and switch NixOS
    updateNixos = ''
      sudo nix-channel --update
      sudo nixos-rebuild switch --flake ~/.config/home-manager
    '';

    # Combined update and switch for both Home Manager and NixOS
    updateAll = ''
      sudo nix-channel --update && \
      nix flake update --flake  ~/.config/home-manager && \
      home-manager switch && \
      sudo nixos-rebuild switch --flake ~/.config/home-manager
    '';
    q = "qalc";
    tldr = ''tldr_wrapper() { tldr "$1" || man "$1" | bat -l man -p; } && tldr_wrapper'';
  };
}
