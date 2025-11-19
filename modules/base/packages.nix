{
  pkgs,
  lib,
  config,
  system,
  ...
}:

let
  corePackages = with pkgs; [
    (btop.override { cudaSupport = true; })
    busybox
    dconf
    dig
    duf
    entr
    gdu
    gitflow
    gitleaks
    glib
    gnumake
    hyperfine # benchmark CLI commands
    imagemagick
    isd
    libqalculate
    libsecret
    miktex
    nix-output-monitor
    nix-prefetch-github
    nix-search-cli
    nixfmt-classic
    onefetch
    python3Packages.keyring
    rename
    silver-searcher
    speedtest-go
    tldr
    unar
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
    onlyoffice-desktopeditors
    pika-backup
    pywal16
    signal-desktop
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
      poppler-utils
      dive
      frogmouth
      visidata
      wakatime-cli
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
      name = "bak";
      runtimeInputs = [
        pkgs.bash
        pkgs.coreutils
      ];
      text = builtins.readFile ../../bin/bak;
    })
    (pkgs.writeShellApplication {
      name = "bhelp";
      runtimeInputs = [ pkgs.bat ];
      text = builtins.readFile ../../bin/bathelp;
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
      name = "dragon-scp";
      runtimeInputs = [
        pkgs.openssh
        pkgs.dragon-drop
        pkgs.coreutils
      ];
      text = builtins.readFile ../../bin/dragon-scp;
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
      name = "hs";
      runtimeInputs = [
        pkgs.home-manager
        pkgs.nix-output-monitor
      ];
      text = builtins.readFile ../../bin/hm-switch;
    })
    (pkgs.writeShellApplication {
      name = "hsu";
      runtimeInputs = [
        pkgs.home-manager
        pkgs.nix-output-monitor
      ];
      text = builtins.readFile ../../bin/hm-switch-update;
    })
    (pkgs.writeShellApplication {
      name = "nix-find";
      runtimeInputs = [
        pkgs.nix-search-tv
        pkgs.fzf
        pkgs.busybox
        pkgs.wl-clipboard
        pkgs.xclip
      ];
      text = builtins.readFile ../../bin/nix-find;
    })
    (pkgs.writeShellApplication {
      name = "nixos-switch";
      runtimeInputs = [ pkgs.nix-output-monitor ];
      text = builtins.readFile ../../bin/nixos-switch;
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
      name = "update-all";
      runtimeInputs = [
        pkgs.home-manager
        pkgs.nix-output-monitor
        pkgs.uv
      ];
      text = builtins.readFile ../../bin/update-all;
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
      name = "icat";
      runtimeInputs = [ pkgs.kitty ];
      text = ''
        exec kitty +kitten icat "$@"
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
