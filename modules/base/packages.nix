{ pkgs, lib, config, system, ... }:

let
  corePackages = with pkgs; [
    (btop.override { cudaSupport = true; })
    (aider-chat.withOptional {
      withBrowser = true;
      withHelp = true;
    })
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

  devPackages = with pkgs;
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
    ] ++ lib.optionals (system != "aarch64-linux") [ jdk ];

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
    (pkgs.writeShellScriptBin "dragon-scp"
      (builtins.readFile ../../bin/dragon-scp))
    (pkgs.writeShellScriptBin "bak" (builtins.readFile ../../bin/bak))
    (pkgs.writeShellScriptBin "emacs-clean"
      (builtins.readFile ../../bin/emacs-clean))
    (pkgs.writeShellScriptBin "bhelp" (builtins.readFile ../../bin/bathelp))
    (pkgs.writeShellScriptBin "pyvenv-setup"
      (builtins.readFile ../../bin/pyvenv-setup))
    (pkgs.writeShellScriptBin "docker-volume-copy"
      (builtins.readFile ../../bin/docker-volume-copy))
    (pkgs.writeShellScriptBin "nix-find"
      (builtins.readFile ../../bin/nix-find))
    (pkgs.writeShellScriptBin "yqp" (builtins.readFile ../../bin/yqp))
    (pkgs.writeShellScriptBin "pywal-apply" ''
      ${pkgs.pywal16}/bin/wal -i "$(${pkgs.coreutils}/bin/cat ~/.config/variety/wallpaper/wallpaper.jpg.txt)"
    '')
  ];
in
{
  options.customPackages = with lib.types; {
    core = lib.mkOption {
      type = listOf package;
      default = corePackages;
      description = "Core packages.";
    };
    gui = lib.mkOption {
      type = listOf package;
      default = guiPackages;
      description = "GUI packages.";
    };
    dev = lib.mkOption {
      type = listOf package;
      default = devPackages;
      description = "Development packages.";
    };
    emacs = lib.mkOption {
      type = listOf package;
      default = emacsPackages;
      description = "Emacs packages.";
    };
    scripts = lib.mkOption {
      type = listOf package;
      default = customScripts;
      description = "Custom scripts packaged from the bin directory.";
    };
    extra = lib.mkOption {
      type = listOf package;
      default = [ ];
      description = "Extra packages for a specific system.";
    };
    exclude = lib.mkOption {
      type = listOf package;
      default = [ ];
      description = "Packages to exclude from the final list.";
    };
  };

  config = let
    cfg = config.customPackages;
    allPackages =
      cfg.core
      ++ cfg.gui
      ++ cfg.dev
      ++ cfg.emacs
      ++ cfg.scripts
      ++ cfg.extra;
  in {
    home.packages =
      lib.filter (p: !(lib.elem p cfg.exclude)) allPackages;
  };
}
