{
  pkgs,
  system,
  lib,
  inputs,
  ...
}:
let
  corePackages = with pkgs; [
    android-tools
    btop
    busybox
    dconf
    dig
    duf
    entr
    fd
    frogmouth
    gdu
    git
    gitflow
    gitleaks
    glib
    gnumake
    onefetch
    hyperfine
    isd
    ispell
    jq
    libqalculate
    libsecret
    nix-output-monitor
    nix-prefetch-github
    nix-search-cli
    nixfmt-classic
    nmap
    nvtopPackages.full
    pandoc
    poppler_utils
    rclone
    rename
    silver-searcher
    speedtest-go
    tldr
    unar
    uv
    wakatime
    xclip
    yq-go
  ];

  guiPackages = with pkgs; [
    brave
    keepassxc
    code-cursor
    dbeaver-bin
    feh
    gnome-boxes
    gnome-pomodoro
    libnotify
    nodePackages.prettier
    onlyoffice-bin
    pika-backup
    pywal16
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
      opencommit
      graphviz
      nerd-fonts.fira-code
      meslo-lgs-nf
      fira-code-symbols
      nodejs
    ]
    ++ lib.optionals (system != "aarch64-linux") [ jdk ];

  # emacs is enabled in programs.nix
  emacsPackages = with pkgs; [
    python312Packages.python-lsp-server
    bash-language-server
    yaml-language-server
    powershell
    taplo
    hunspell
    nixd
    texlab
    silver-searcher
    aspellDicts.da
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science
    python3
    marksman
    autotools-language-server
    wl-clipboard-rs
  ];

  customScripts = [
    (pkgs.writeShellScriptBin "dragon-scp" (builtins.readFile ./bin/dragon-scp))
    (pkgs.writeScriptBin "find-available-server" (builtins.readFile ./bin/find-available-server))
    (pkgs.writeShellScriptBin "bak" (builtins.readFile ./bin/bak))
    (pkgs.writeShellScriptBin "pyenv-here" (builtins.readFile ./bin/pyenv-here))
    (pkgs.writeShellScriptBin "emacs-clean" (builtins.readFile ./bin/emacs-clean))
    (pkgs.writeShellScriptBin "bhelp" (builtins.readFile ./bin/bathelp))
    (pkgs.writeShellScriptBin "pyvenv-setup" (builtins.readFile ./bin/pyvenv-setup))
    (pkgs.writeShellScriptBin "docker-volume-copy" (builtins.readFile ./bin/docker-volume-copy))
    (pkgs.writeShellScriptBin "pywal-apply" ''
      ${pkgs.pywal16}/bin/wal -i "$(${pkgs.coreutils}/bin/cat ~/.config/variety/wallpaper/wallpaper.jpg.txt)"
    '')
  ];
in
{
  inherit
    corePackages
    devPackages
    customScripts
    emacsPackages
    guiPackages
    ;
}
