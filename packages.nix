{ pkgs, ... }:
let
  hyprLandPackages = with pkgs; [
    dolphin
    pywal
    wdisplays
  ];

  corePackages = with pkgs; [
    atuin
    bat
    btop
    cookiecutter
    dconf
    dig
    duf
    entr
    fd
    gdu
    gitflow
    gitleaks
    glib
    gnumake
    ispell
    jq
    libqalculate
    neofetch
    nix-index
    nix-prefetch-github
    pandoc
    rename
    speedtest-go
    t-rec
    taplo
    texlive.combined.scheme-full
    texlivePackages.fontawesome5
    tldr
    unzip
    wakatime
    wget
    xclip
    xdragon
    zip
  ];

  guiPackages = with pkgs; [
    konsole
    brave
    dbeaver-bin
    feh
    firefox
    gnome-pomodoro
    keepassxc
    onlyoffice-bin
    # pika-backup
    nodePackages.prettier
    signal-desktop
    slack
    variety
    virt-manager
    xorg.xkill
    spotify
    yubikey-personalization-gui
  ];

  devPackages = with pkgs; [
    lurk
    graphviz
    fira-code-nerdfont
    meslo-lgs-nf
    fira-code-symbols
    sonar-scanner-cli
    jdk
    nodejs
  ];

  emacs_packages = with pkgs; [
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
  ];

  customScripts = [
    (pkgs.writeShellScriptBin "dragon-scp" (builtins.readFile ./bin/dragon-scp))
    (pkgs.writeScriptBin "find-available-server" (builtins.readFile ./bin/find-available-server))
    (pkgs.writeShellScriptBin "unzipd" (builtins.readFile ./bin/unzipd))
    (pkgs.writeShellScriptBin "bak" (builtins.readFile ./bin/bak))
    (pkgs.writeShellScriptBin "pyenv-here" (builtins.readFile ./bin/pyenv-here))
    (pkgs.writeShellScriptBin "emacs-clean" (builtins.readFile ./bin/emacs-clean))
  ];
in
{
  home.packages = corePackages ++ guiPackages ++ devPackages ++ customScripts ++ emacs_packages ++ hyprLandPackages;
}
