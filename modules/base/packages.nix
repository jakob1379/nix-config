{
  pkgs,
  lib,
  config,
  system,
  inputs,
  ...
}:

let
  mkAiderWrapper =
    {
      name,
      keyringService,
      keyringUsername,
      envVars ? { },
    }:
    pkgs.writeShellApplication {
      name = name;
      runtimeInputs = [
        pkgs.bash
        pkgs.python3Packages.keyring
        pkgs.aider-chat-full
      ];
      text = ''
        #!${pkgs.bash}/bin/bash

        API_KEY="$(keyring get ${keyringService} ${keyringUsername} 2>/dev/null)"
        if [ -z "$API_KEY" ]; then
          echo "Error: Failed to retrieve API key from keyring: service='${keyringService}' account='${keyringUsername}'." >&2
          exit 1
        fi

        # Common settings
        export AIDER_CACHE_PROMPTS=true
        export AIDER_CHECK_UPDATE=false
        export AIDER_ANALYTICS=false
        export AIDER_NOTIFICATIONS=true

        # Provider-specific settings
        ${builtins.concatStringsSep "\n" (
          builtins.attrValues (builtins.mapAttrs (k: v: "export ${k}=${v}") envVars)
        )}

        exec aider "$@"
      '';
    };

  aiderWrapper-gemini = mkAiderWrapper {
    name = "aider";
    keyringService = "gemini";
    keyringUsername = "api_key";
    envVars = {
      GEMINI_API_KEY = "$API_KEY";
      AIDER_MODEL = "gemini/gemini-2.5-pro";
      AIDER_WEAK_MODEL = "gemini/gemini-2.5-flash-lite";
      AIDER_THINKING_TOKENS = "32k";
    };
  };

  aiderWrapper-gpt = mkAiderWrapper {
    name = "aider-gpt";
    keyringService = "openai";
    keyringUsername = "mds245";
    envVars = {
      OPENAI_API_KEY = "$API_KEY";
      AIDER_MODEL = "openai/gpt-5";
      AIDER_WEAK_MODEL = "openai/gpt-5-nano";
    };
  };

  karakeepWrapper = pkgs.writeShellApplication {
    name = "karakeep";
    runtimeInputs = [
      pkgs.bash
      pkgs.python3Packages.keyring
      pkgs.karakeep
    ];
    text = ''
      #!${pkgs.bash}/bin/bash

      API_KEY="$(keyring get hoarder.jgalabs.dk api_key || exit 1)"

      export KARAKEEP_API_KEY="$API_KEY"
      export KARAKEEP_SERVER_ADDR="https://hoarder.jgalabs.dk"

      exec karakeep "$@"
    '';
  };


  corePackages = with pkgs; [
    (btop.override { cudaSupport = true; })
    busybox
    dconf
    dig
    duf
    entr
    fd
    gdu
    git
    gitflow
    gitleaks
    glib
    gnumake
    hyperfine # benchmark CLI commands
    imagemagick
    isd
    jq
    jqp
    libqalculate
    libsecret
    miktex
    nix-init
    nix-output-monitor
    nix-prefetch-github
    nix-search-cli
    nixfmt-classic
    nvtopPackages.full
    onefetch
    python3Packages.keyring
    rclone
    rename
    silver-searcher
    speedtest-go
    tldr
    unar
    xclip
    yq-go
  ];

  guiPackages = with pkgs; [
    brave
    tana
    dbeaver-bin
    feh
    gnome-boxes
    gnome-pomodoro
    keepassxc
    libnotify
    nodePackages.prettier
    onlyoffice-bin
    pika-backup
    pywal16
    signal-desktop
    slack
    spotify
    stretchly
    thunderbird
    variety
    virt-manager
    vlc
    xdg-desktop-portal-wlr
    dragon-drop
    xorg.xkill
  ];

  devPackages =
    with pkgs;
    [
      android-tools
      graphviz
      meslo-lgs-nf
      nerd-fonts.fira-code
      nodejs
      pandoc
      poppler_utils
      uv
      aiderWrapper-gemini
      aiderWrapper-gpt
      dive
      frogmouth
      karakeepWrapper
      visidata
      wakatime
    ]
    ++ lib.optionals (system != "aarch64-linux") [ jdk ];

  emacsPackages = with pkgs; [
    autotools-language-server
    (aspellWithDicts (
      dicts: with dicts; [
        da
        en
        en-computers
        en-science
      ]
    ))
    bash-language-server
    hunspell
    ispell
    marksman
    nixd
    powershell
    python3
    python313Packages.python-lsp-server
    silver-searcher
    taplo
    texlab
    wl-clipboard-rs
    yaml-language-server
  ];

  customScripts = [
    (pkgs.writeShellApplication {
      name = "dragon-scp";
      runtimeInputs = [
        pkgs.openssh
        pkgs.dragon-drop
        pkgs.coreutils
      ];
      text = builtins.readFile ../../bin/dragon-scp;
    })
    (pkgs.writeShellApplication {
      name = "bak";
      runtimeInputs = [
        pkgs.bash
        pkgs.coreutils
      ];
      text = builtins.readFile ../../bin/bak;
    })
    (pkgs.writeShellApplication {
      name = "emacs-clean";
      runtimeInputs = [
        pkgs.bash
        pkgs.fd
        pkgs.findutils
        pkgs.coreutils
      ];
      text = builtins.readFile ../../bin/emacs-clean;
    })
    (pkgs.writeShellApplication {
      name = "bhelp";
      runtimeInputs = [
        pkgs.bat
      ];
      text = builtins.readFile ../../bin/bathelp;
    })
    (pkgs.writeShellApplication {
      name = "pyvenv-setup";
      runtimeInputs = [
        pkgs.bash
        pkgs.nix
        pkgs.direnv
        pkgs.uv
      ];
      text = builtins.readFile ../../bin/pyvenv-setup;
    })
    (pkgs.writeShellApplication {
      name = "docker-volume-copy";
      runtimeInputs = [
        pkgs.docker
        pkgs.alpine
      ];
      text = builtins.readFile ../../bin/docker-volume-copy;
    })
    (pkgs.writeShellApplication {
      name = "yqp";
      runtimeInputs = [
        pkgs.yq-go
        pkgs.fzf
        pkgs.bat
        pkgs.coreutils
      ];
      text = builtins.readFile ../../bin/yqp;
    })
    (pkgs.writeShellApplication {
      name = "pywal-apply";
      runtimeInputs = [
        pkgs.pywal16
        pkgs.coreutils
      ];
      text = ''
        wal -i "$(cat ~/.config/variety/wallpaper/wallpaper.jpg.txt)"
      '';
    })
    (pkgs.writeShellApplication {
      name = "nix-find";
      runtimeInputs = [
        pkgs.nix-search-tv
        pkgs.fzf
      ];
      text = ''
        nix-search-tv print | fzf --query="''${1:-}" --preview 'nix-search-tv preview {}' --scheme history
      '';
    })
  ];
in
{
  options.customPackages = {
    enableCore = lib.mkEnableOption "core packages";
    enableGui = lib.mkEnableOption "GUI packages";
    enableDev = lib.mkEnableOption "development packages";
    enableEmacs = lib.mkEnableOption "Emacs packages";
    enableScripts = lib.mkEnableOption "custom scripts";

    extra = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra packages for a specific system.";
    };
    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Packages to exclude from the final list.";
    };
  };

  config =
    let
      cfg = config.customPackages;
      allPackages =
        (lib.optionals cfg.enableCore corePackages)
        ++ (lib.optionals cfg.enableGui guiPackages)
        ++ (lib.optionals cfg.enableDev devPackages)
        ++ (lib.optionals cfg.enableEmacs emacsPackages)
        ++ (lib.optionals cfg.enableScripts customScripts)
        ++ cfg.extra;
    in
    {
      home.packages = lib.filter (p: !(lib.elem p cfg.exclude)) allPackages;
    };
}
