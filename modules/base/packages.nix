{
  pkgs,
  lib,
  config,
  system,
  ...
}:

let
  aiderWrapper = pkgs.writeScriptBin "aider" ''
    #!${pkgs.bash}/bin/bash

    API_KEY="$(${pkgs.python3Packages.keyring}/bin/keyring get gemini api_key || exit 1)"

    export GEMINI_API_KEY="$API_KEY"
    export AIDER_MODEL="gemini/gemini-2.5-pro-preview-06-05"
    export AIDER_WEAK_MODEL="gemini/gemini-2.5-flash-preview-05-20"
    export AIDER_THINKING_TOKENS="32k"
    export AIDER_CHECK_UPDATE="false"
    export AIDER_ANALYTICS="false"
    export AIDER_NOTIFICATIONS="true"

    exec ${pkgs.aider-chat-full}/bin/aider "$@"
  '';

  opencommitWrapper = pkgs.writeScriptBin "oco" ''
    #!${pkgs.bash}/bin/bash

    export OPENAI_API_KEY="$(${pkgs.python3Packages.keyring}/bin/keyring get opencommit api_key || exit 1)"

    exec ${pkgs.opencommit}/bin/opencommit "$@"
  '';

  karakeepWrapper = pkgs.writeScriptBin "karakeep" ''
    #!${pkgs.bash}/bin/bash

    API_KEY="$(${pkgs.python3Packages.keyring}/bin/keyring get hoarder.jgalabs.dk api_key || exit 1)"

    export KARAKEEP_API_KEY="$API_KEY"
    export KARAKEEP_SERVER_ADDR="https://hoarder.jgalabs.dk"

    exec ${pkgs.karakeep}/bin/karakeep "$@"
  '';

  corePackages = with pkgs; [
    (btop.override { cudaSupport = true; })
    busybox
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
    hyperfine # benchmark CLI commands
    imagemagick
    isd
    jq
    jqp
    libqalculate
    libsecret
    mergiraf
    miktex
    nix-init
    nix-output-monitor
    nix-prefetch-github
    nix-search-cli
    nixfmt-classic
    nmap
    nvtopPackages.full
    onefetch
    python3Packages.keyring
    rclone
    rename
    silver-searcher
    speedtest-go
    tldr
    unar
    xclip
    yq-go
  ];

  guiPackages = with pkgs; [
    brave
    code-cursor
    dbeaver-bin
    feh
    gnome-boxes
    gnome-pomodoro
    keepassxc
    libnotify
    nodePackages.prettier
    onlyoffice-bin
    pika-backup
    pywal16
    signal-desktop
    slack
    spotify
    stretchly
    thunderbird
    variety
    virt-manager
    vlc
    xdg-desktop-portal-wlr
    xdragon
    xorg.xkill
  ];

  devPackages =
    with pkgs;
    [
      android-tools
      distrobox
      graphviz
      meslo-lgs-nf
      nerd-fonts.fira-code
      nodejs
      opencommitWrapper
      pandoc
      poppler_utils
      uv
      aiderWrapper
      dive
      frogmouth
      karakeepWrapper
      visidata
      wakatime
    ]
    ++ lib.optionals (system != "aarch64-linux") [ jdk ];

  emacsPackages = with pkgs; [
    ispell
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
    (pkgs.writeShellScriptBin "dragon-scp" (builtins.readFile ../../bin/dragon-scp))
    (pkgs.writeShellScriptBin "bak" (builtins.readFile ../../bin/bak))
    (pkgs.writeShellScriptBin "emacs-clean" (builtins.readFile ../../bin/emacs-clean))
    (pkgs.writeShellScriptBin "bhelp" (builtins.readFile ../../bin/bathelp))
    (pkgs.writeShellScriptBin "pyvenv-setup" (builtins.readFile ../../bin/pyvenv-setup))
    (pkgs.writeShellScriptBin "docker-volume-copy" (builtins.readFile ../../bin/docker-volume-copy))
    (pkgs.writeShellScriptBin "nix-find" (builtins.readFile ../../bin/nix-find))
    (pkgs.writeShellScriptBin "yqp" (builtins.readFile ../../bin/yqp))
    (pkgs.writeShellScriptBin "pywal-apply" ''
      ${pkgs.pywal16}/bin/wal -i "$(${pkgs.coreutils}/bin/cat ~/.config/variety/wallpaper/wallpaper.jpg.txt)"
    '')
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
