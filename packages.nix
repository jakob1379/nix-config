{
  pkgs,
  system,
  lib,
  inputs,
  ...
}:
let
  patched_keepassxc = pkgs.keepassxc.overrideAttrs (oldAttrs: {
    postFixup = ''
      sed -i 's/^Exec=keepassxc/Exec=keepassxc -platform xcb/' \
        $out/share/applications/org.keepassxc.KeePassXC.desktop
    '';
  });

  corePackages = with pkgs; [
    android-tools
    unar
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
    inputs.isd.packages.${system}.default
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
    uv
    wakatime
    xclip
    yq-go
  ];

  guiPackages = with pkgs; [
    appflowy
    brave
    pywal16
    gnome-boxes
    code-cursor
    dbeaver-bin
    feh
    gnome-pomodoro
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
    (pkgs.writeShellScriptBin "time-stats" (builtins.readFile ./bin/time-stats))
    (pkgs.writeShellScriptBin "bhelp" (builtins.readFile ./bin/bathelp))
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
    ;
  guiPackages = guiPackages ++ [ patched_keepassxc ];
}
