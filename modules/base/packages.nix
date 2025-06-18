{
  pkgs,
  lib,
  config,
  system,
  ...
}:

let
  aiderChatWithBrowserHelp = pkgs.aider-chat.withOptional {
    withBrowser = true;
    withHelp = true;
  };
  # Define the custom aider wrapper script here
  aiderWrapper = pkgs.writeScriptBin "aider" ''
    #!${pkgs.bash}/bin/bash
    
    API_KEY="$(${pkgs.python3Packages.keyring}/bin/keyring get gemini api_key || exit 1)"

    export GEMINI_API_KEY="$API_KEY"
    export AIDER_MODEL="gemini/gemini-2.5-pro-preview-06-05"
    export AIDER_WEAK_MODEL="gemini/gemini-2.5-flash-preview-05-20"
    export AIDER_THINKING_TOKENS="32k"
    export AIDER_CHECK_UPDATE="false";
    export AIDER_ANALYTICS="false";

    exec ${aiderChatWithBrowserHelp}/bin/aider "$@"
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
    aiderWrapper
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
    hyperfine # benchmark CLI commands
    isd
    jq
    jqp
    karakeepWrapper
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
      wakatime
      pandoc
      opencommit
      android-tools
      graphviz
      nodejs
      poppler_utils
      uv
      nerd-fonts.fira-code
      meslo-lgs-nf
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
