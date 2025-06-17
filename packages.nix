{
  pkgs,
  system,
  lib,
  inputs,
  ...
}:
let
  corePackages = with pkgs; [
    (btop.override { cudaSupport = true; })
    (aider-chat.withOptional { withBrowser = true; })
    android-tools
    busybox
    dconf
    dig
    dive
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
    hyperfine
    isd
    ispell
    jq
    jqp
    karakeep
    libqalculate
    libsecret
    miktex
    nix-output-monitor
    nix-prefetch-github
    nix-search-cli
    nixfmt-classic
    nmap
    nvtopPackages.full
    onefetch
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
    thunderbird
    xdragon
    xorg.xkill
    vlc
  ];

  devPackages =
    with pkgs;
    [
      opencommit
      graphviz
      nerd-fonts.fira-code
      meslo-lgs-nf
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
    (pkgs.writeShellScriptBin "bak" (builtins.readFile ./bin/bak))
    (pkgs.writeShellScriptBin "bhelp" (builtins.readFile ./bin/bathelp))
    (pkgs.writeShellScriptBin "docker-volume-copy" (builtins.readFile ./bin/docker-volume-copy))
    (pkgs.writeShellScriptBin "dragon-scp" (builtins.readFile ./bin/dragon-scp))
    (pkgs.writeShellScriptBin "emacs-clean" (builtins.readFile ./bin/emacs-clean))
    (pkgs.writeShellScriptBin "nix-find" (builtins.readFile ./bin/nix-find))
    (pkgs.writeShellScriptBin "pyvenv-setup" (builtins.readFile ./bin/pyvenv-setup))
    (pkgs.writeShellScriptBin "pywal-apply" ''
      ${pkgs.pywal16}/bin/wal -i "$(${pkgs.coreutils}/bin/cat ~/.config/variety/wallpaper/wallpaper.jpg.txt)"
    '')
    (pkgs.writeShellScriptBin "yqp" (builtins.readFile ./bin/yqp))
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
