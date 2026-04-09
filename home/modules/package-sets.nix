{
  pkgs,
  lib,
  system,
}:

{
  core = with pkgs; [
    btop
    git-filter-repo
    busybox
    dconf
    duf
    entr
    gdu
    gitleaks
    glib
    gnumake
    unixtools.ping
    hyperfine
    imagemagick
    isd
    libqalculate
    libsecret
    nix-output-monitor
    nix-prefetch-github
    nix-search-cli
    onefetch
    python3Packages.keyring
    rename
    silver-searcher
    speedtest-go
    tldr
    unar
    yq-go
  ];

  gui = with pkgs; [
    brave
    tana
    noctalia-shell
    xwayland-satellite
    wdisplays
    wifi-qr
    feh
    swaybg
    libnotify
    prettier
    onlyoffice-desktopeditors
    pika-backup
    signal-desktop
    spotify
    stretchly
    udiskie
    variety
    virt-manager
    vlc
    dragon-drop
    xkill
  ];

  dev =
    with pkgs;
    [
      graphviz
      meslo-lgs-nf
      nerd-fonts.fira-code
      nodejs
      pandoc
      poppler-utils
      dive
      frogmouth
      wakatime-cli
      mermaid-cli
    ]
    ++ lib.optionals (system != "aarch64-linux") [ jdk ];

  emacs = with pkgs; [
    autotools-language-server
    just-lsp
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
    silver-searcher
    taplo
    texlab
    wl-clipboard-rs
    yaml-language-server
  ];

  scripts = [
    (pkgs.writeShellApplication {
      name = "nb-peers";
      runtimeInputs = [
        pkgs.jq
        pkgs.netbird
      ];
      text = builtins.readFile ../../bin/nb-peers;
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
      name = "bhelp";
      runtimeInputs = [ pkgs.bat ];
      text = builtins.readFile ../../bin/bathelp;
    })
    (pkgs.writeShellApplication {
      name = "docker-volume-copy";
      runtimeInputs = [
        pkgs.docker
      ];
      text = builtins.readFile ../../bin/docker-volume-copy;
    })
    (pkgs.writeShellApplication {
      name = "ooc";
      runtimeInputs = [
        pkgs.bash
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.gnused
        pkgs.opencode
        pkgs.util-linux
      ];
      text = builtins.readFile ../../bin/ooc;
    })
    (pkgs.writeShellApplication {
      name = "docker-compose-deps";
      runtimeInputs = with pkgs; [
        docker-compose
        jq
        mermaid-cli
        kitty
      ];
      text = builtins.readFile ../../bin/docker-compose-deps;
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
      name = "ag-fuzzy";
      runtimeInputs = [
        pkgs.silver-searcher
        pkgs.fzf
        pkgs.bat
        pkgs.wl-clipboard
      ];
      text = builtins.readFile ../../bin/ag-fuzzy;
    })
    (pkgs.writeShellApplication {
      name = "nixos-switch";
      runtimeInputs = [ pkgs.nix-output-monitor ];
      text = builtins.readFile ../../bin/nixos-switch;
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
      name = "up";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.gum
      ];
      text = builtins.readFile ../../bin/up;
    })
    (pkgs.writeShellApplication {
      name = "icat";
      runtimeInputs = [ pkgs.kitty ];
      text = ''
        exec kitty +kitten icat "$@"
      '';
    })
    (pkgs.writeShellApplication {
      name = "noqa-stats";
      runtimeInputs = [
        pkgs.gum
        pkgs.silver-searcher
      ];
      text = builtins.readFile ../../bin/noqa-stats;
    })
    (pkgs.writeShellApplication {
      name = "nix-index-with-temp-swap";
      runtimeInputs = with pkgs; [
        nix-index
        coreutils
        util-linux
      ];
      text = builtins.readFile ../../bin/nix-index-swap;
    })
    (pkgs.writeShellApplication {
      name = "display-mode-picker";
      runtimeInputs = with pkgs; [
        coreutils
        jq
        libnotify
        niri
        vicinae
        wl-mirror
      ];
      text = builtins.readFile ../../bin/display-mode-picker;
    })
  ];
}
