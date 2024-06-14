{ pkgs, inputs, ... }:

let
  hyprLandPackages = with pkgs; [
    dolphin
    pywal
    wdisplays
  ];


  lspPackages = with pkgs; [
    powershell
  ];

  cliPackages = with pkgs; [
    apacheHttpd # webserver and htpasswd
    aspellDicts.da
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science
    atuin
    bat
    btop
    clinfo
    dconf
    dig
    duf
    entr
    fd
    fira-code-nerdfont
    fira-code-symbols
    fzf
    gdu
    gitleaks
    glib
    glxinfo
    gnome.cheese
    gnumake
    gum
    hunspell
    imagemagick
    inkscape
    iputils
    ispell
    jq
    killall
    libjpeg
    libqalculate
    neofetch
    nil
    nix-index
    nix-prefetch-github
    nodejs
    pandoc
    pciutils
    poetry
    python311Packages.python-lsp-server
    sonar-scanner-cli
    speedtest-go
    t-rec
    taplo
    termdown
    texlab
    rename
    texlive.combined.scheme-full
    texlivePackages.fontawesome5
    tldr
    unixtools.ping
    unzip
    wakatime
    wget
    xclip
    xdragon
    zip
  ];
  guiPackages = with pkgs; [
    konsole
    gnome.gnome-boxes
    alacritty
    brave
    dbeaver-bin
    feh
    firefox
    gimp
    gnome.pomodoro
    kazam
    keepassxc
    onlyoffice-bin
    openscad
    pika-backup
    prusa-slicer
    screenkey
    nodePackages.prettier
    signal-desktop
    slack
    variety
    virt-manager
    xorg.xkill
    spotify
    yubikey-personalization-gui
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
  home.packages = cliPackages ++ guiPackages ++ customScripts ++ hyprLandPackages;
}
