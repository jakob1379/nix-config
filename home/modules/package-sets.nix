{
  pkgs,
  lib,
  system,
  inputs,
  ...
}:

let
  hsu = pkgs.writeShellApplication {
    name = "hsu";
    runtimeInputs = [
      pkgs.gh
      pkgs.nh
    ];
    text = builtins.readFile ../../bin/hm-switch-update;
  };
in
{
  core = with pkgs; [
    # keep-sorted start block=yes
    # applet symlinks off: they shadow coreutils/gnugrep/gnused on PATH
    (busybox.override { enableAppletSymlinks = false; })
    betterleaks
    btop
    dconf
    duf
    entr
    gdu
    git-filter-repo
    glib
    gnumake
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
    ripgrep
    speedtest-go
    tldr
    unar
    unixtools.ping
    yq-go
    # keep-sorted end
  ];

  gui = with pkgs; [
    # keep-sorted start block=yes
    (pkgs.writeShellApplication {
      name = "screenshot-ocr";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.flameshot
        pkgs.tesseract
        pkgs.wl-clipboard
      ];
      text = builtins.readFile ../../bin/screenshot-ocr;
    })
    brave
    dragon-drop
    feh
    flameshot
    inputs.ai-usagebar.packages.${system}.default
    libnotify
    onlyoffice-desktopeditors
    pika-backup
    prettier
    signal-desktop
    spotify
    stretchly
    swaybg
    tana
    udiskie
    variety
    virt-manager
    vlc
    wdisplays
    wifi-qr
    xkill
    xwayland-satellite
    # keep-sorted end
  ];

  dev =
    with pkgs;
    [
      # keep-sorted start block=yes
      bun
      dive
      frogmouth
      glab
      graphviz
      mermaid-cli
      meslo-lgs-nf
      nerd-fonts.fira-code
      nodejs
      nurl
      pandoc
      poppler-utils
      t3code
      wakatime-cli
      # keep-sorted end
    ]
    ++ lib.optionals (system != "aarch64-linux") [ jdk ];

  emacs = with pkgs; [
    # keep-sorted start block=yes
    (aspellWithDicts (
      dicts: with dicts; [
        da
        en
        en-computers
        en-science
      ]
    ))
    # Stable-named python that always has debugpy importable, so dape's
    # adapter works regardless of which project venv is active.
    (writeShellScriptBin "python-dap" ''
      exec ${python3.withPackages (ps: [ ps.debugpy ])}/bin/python "$@"
    '')
    autotools-language-server
    bash-language-server
    hunspell
    ispell
    just-lsp
    marksman
    nixd
    powershell
    python3
    python3Packages.jedi-language-server
    rassumfrassum
    ripgrep
    ruff
    taplo
    texlab
    tinymist
    ty
    vscode-langservers-extracted
    vtsls
    wl-clipboard-rs
    yaml-language-server
    # keep-sorted end
  ];

  scripts = [
    # keep-sorted start block=yes
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
      name = "docker-volume-copy";
      runtimeInputs = [
        pkgs.docker
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
      name = "git-worktree-cd";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.eza
        pkgs.findutils
        pkgs.fzf
        pkgs.git
      ];
      text = builtins.readFile ../../bin/git-worktree-cd;
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
      name = "icat";
      runtimeInputs = [ pkgs.kitty ];
      text = ''
        exec kitty +kitten icat "$@"
      '';
    })
    (pkgs.writeShellApplication {
      name = "nb-peers";
      runtimeInputs = [
        pkgs.jq
        pkgs.netbird
      ];
      text = builtins.readFile ../../bin/nb-peers;
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
      name = "noqa-stats";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.gawk
        pkgs.ripgrep
      ];
      text = builtins.readFile ../../bin/noqa-stats;
    })
    (pkgs.writeShellApplication {
      name = "rg-fuzzy";
      runtimeInputs = [
        pkgs.ripgrep
        pkgs.fzf
        pkgs.bat
        pkgs.wl-clipboard
      ];
      text = builtins.readFile ../../bin/rg-fuzzy;
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
      name = "update-all";
      runtimeInputs = [
        hsu
        pkgs.coreutils
        pkgs.nh
        pkgs.nix
        pkgs.uv
      ];
      text = builtins.readFile ../../bin/update-all;
    })
    hsu
    # keep-sorted end
  ];
}
