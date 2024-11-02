{ pkgs, system, ... }:
let
  hyprLandPackages = with pkgs; [
    dolphin
    pywal
    wdisplays
  ];

  corePackages = with pkgs; [
    btop
    cookiecutter
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
    ispell
    jq
    libqalculate
    nix-index
    nix-prefetch-github
    nixfmt-classic
    nmap
    pandoc
    rclone
    rename
    speedtest-go
    t-rec
    taplo
    # texlive.combined.scheme-full
    # texlivePackages.fontawesome5
    tldr
    unzip
    uv
    wakatime
    wget
    xclip
    yq-go
    zip
  ];

  guiPackages = with pkgs; [
    code-cursor
    brave
    dbeaver-bin
    feh
    firefox-unwrapped
    gnome-pomodoro
    keepassxc
    konsole
    nodePackages.prettier
    onlyoffice-bin
    pika-backup
    signal-desktop
    slack
    spotify
    stretchly
    variety
    virt-manager
    xdg-desktop-portal-wlr
    xdragon
    xorg.xkill
    yubikey-personalization-gui
  ];

  devPackages =
    with pkgs;
    [
      graphviz
      fira-code-nerdfont
      meslo-lgs-nf
      fira-code-symbols
      nodejs
    ]
    ++ lib.optionals (system != "aarch64-linux") [ jdk ];

  # emacs is enabled in programs.nix
  emacsPackages = with pkgs; [
    python312Packages.python-lsp-server
    powershell
    hunspell
    nil
    texlab
    silver-searcher
    aspellDicts.da
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science
    marksman
    wl-clipboard-rs
  ];

  customScripts = [
    (pkgs.writeShellScriptBin "dragon-scp" (builtins.readFile ./bin/dragon-scp))
    (pkgs.writeScriptBin "find-available-server" (builtins.readFile ./bin/find-available-server))
    (pkgs.writeShellScriptBin "unzipd" (builtins.readFile ./bin/unzipd))
    (pkgs.writeShellScriptBin "bak" (builtins.readFile ./bin/bak))
    (pkgs.writeShellScriptBin "pyenv-here" (builtins.readFile ./bin/pyenv-here))
    (pkgs.writeShellScriptBin "emacs-clean" (builtins.readFile ./bin/emacs-clean))
    (pkgs.writeShellScriptBin "time-stats" (builtins.readFile ./bin/time-stats))
    (pkgs.writeShellScriptBin "bhelp" (builtins.readFile ./bin/bathelp))
  ];
in
{
  inherit
    corePackages
    guiPackages
    devPackages
    customScripts
    emacsPackages
    ;
}
