{
  pkgs,
  system,
  lib,
  ...
}:
let
  isWayland = (builtins.getEnv "XDG_SESSION_TYPE" == "wayland");

  # Conditionally wrap KeePassXC for autotype support in KDE if running Wayland
  patched_keepassxc = pkgs.keepassxc.overrideAttrs (oldAttrs: rec {
    postFixup = ''
      sed -i 's/^Exec=keepassxc/Exec=env QT_QPA_PLATFORM=xcb keepassxc/' \
        $out/share/applications/org.keepassxc.KeePassXC.desktop
    '';
  });

  hyprLandPackages = with pkgs; [
    dolphin
    wdisplays
  ];

  corePackages = with pkgs; [
    # texlive.combined.scheme-full
    # texlivePackages.fontawesome5
    btop
    busybox
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
    android-tools
    libqalculate
    libsecret
    nix-prefetch-github
    nix-search-cli
    nixfmt-classic
    nmap
    pandoc
    rclone
    rename
    speedtest-go
    t-rec
    taplo
    tldr
    uv
    wakatime
    xclip
    yq-go
    poppler_utils
  ];

  guiPackages = with pkgs; [
    brave
    pywal16
    gnome-boxes
    code-cursor
    dbeaver-bin
    feh
    firefox-unwrapped
    gnome-pomodoro
    konsole
    libnotify
    netbird-ui
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
      nerd-fonts.fira-code
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
    nixd
    texlab
    silver-searcher
    aspellDicts.da
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science
    marksman
    autotools-language-server
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
    (pkgs.writeShellScriptBin "docker-volume-copy" (builtins.readFile ./bin/docker-volume-copy))
    (pkgs.writeShellScriptBin "pywal-apply" (''
        ${pkgs.pywal16}/bin/wal -n -i "$(${pkgs.coreutils}/bin/cat ~/.config/variety/wallpaper/wallpaper.jpg.txt)"
      ''))
  ];
in
{
  inherit
    corePackages
    devPackages
    customScripts
    emacsPackages
    ;
  guiPackages = guiPackages ++ [ patched_keepassxc ];
}
