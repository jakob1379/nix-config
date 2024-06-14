{ pkgs, ... }:

{
  programs = {
    atuin = {
      enable = true;
      enableBashIntegration = true;
      flags = [ "--disable-up-arrow" ];
    };

    bash = {
      enable = true;
    };

    direnv = {
      enable = true;
      enableBashIntegration = true;
    };

    pyenv.enable = true;

    readline = {
      enable = true;
      extraConfig = ''
      set completion-ignore-case On
      set completion-prefix-display-length 3
      set mark-symlinked-directories On
      set show-all-if-ambiguous On
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
      icons = true;
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
            # "media.av1.enabled" = false;
            # "media.ffmpeg.vaapi.enabled" = true;
            # "media.ffvpx.enabled" = false;
            "webgl.force-enabled" = true;
            "webgl.msaa-force" = true;

            # Enable css to hide tab bar
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

            # Don't auto open download panel
            "browser.download.alwaysOpenPanel" = false;
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
      userEmail = "jakob.aaes@res-group.com";
      signing = {
        key = "98BD7E80842C97BA";
        signByDefault = false;
      };
      extraConfig = {
        push.autoSetupRemote = true;
        init.defaultBranch = "main";
      };
      aliases = {
        adog = "log --all --decorate --oneline --graph";
        plog = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --branches --all";
      };

    };

    emacs = {
      enable = true;
      package = pkgs.emacs29-gtk3;
    };
    ssh.forwardAgent = true;

    fzf = {
      enable = true;
      enableBashIntegration = true;
    };
  };

  home.shellAliases = {
    tldr = ''tldr_wrapper() { tldr "$1" || man "$1" | bat -l man -p; } && tldr_wrapper'';
    ec = "emacsclient -n";
    grep = "grep --color=auto";
    hu = "nix flake update --flake /home/jga/.config/home-manager/";
    hs = "home-manager switch";
    nhu = "sudo nixos-rebuild switch --flake ~/.config/nixos# --upgrade-all && cd ~/.config/home-manager && nix flake update && home-manager switch";
    nixu = "sudo nixos-rebuild switch --flake ~/.config/nixos# --upgrade-all";
    ns = "sudo nixos-rebuild switch --flake ~/.config/nixos#";
    dx = "dragon --and-exit";
    dk = "dragon --keep";
    eda = "nix-shell -p python312Packages.requests python312Packages.rich python312Packages.ipython python312Packages.pandas python312Packages.seaborn python312Packages.plotly";
    dcview = "docker compose config | bat -l yml";
    dcup = "docker compose up --remove-orphans";
  };
}
