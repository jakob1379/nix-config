{
  pkgs,
  lib,
  config,
  ...
}:

{
  options.customDotfiles = {
    enableDroid = lib.mkEnableOption "media control dotfiles";
    droid = lib.mkOption {
      type = lib.types.attrs;
      default =
        let
          droidDir = config.home.homeDirectory + "/.config/home-manager/dotfiles/droid";
          mkSymlink = name: {
            name = ".factory/${name}";
            value = {
              source = config.lib.file.mkOutOfStoreSymlink (droidDir + "/${name}");
            };
          };
        in
        lib.mapAttrs' (name: _: mkSymlink name) (builtins.readDir (../../dotfiles/droid));
      description = "Factory droid configs";
    };

    enableEmacs = lib.mkEnableOption "Emacs dotfiles";
    emacs = lib.mkOption {
      type = lib.types.attrs;
      default = {
        ".emacs.d/config.org".source = ../../dotfiles/emacs/config.org;
        ".emacs.d/init.el".source = ../../dotfiles/emacs/init.el;
        ".local/share/bash-completion/completions/emacs".source =
          ../../scripts/completions/emacs-completions.sh;
      };
      description = "Emacs dotfiles.";
    };

    enableMediaControl = lib.mkEnableOption "media control dotfiles";
    mediaControl = lib.mkOption {
      type = lib.types.attrs;
      default = {
        ".config/pipewire/media-session.d/bluez-monitor.conf".text = ''
          properties = {
            bluez5.msbc-support = true;
                      }
        '';
      };
      description = "Media control dotfiles.";
    };
  };

  config =
    let
      cfg = config.customDotfiles;
      varietyAutostartDesktop = pkgs.writeText "variety.desktop" (
        builtins.replaceStrings
          [
            "@bash@"
            "@variety@"
            "@home@"
          ]
          [
            "${pkgs.bash}/bin/bash"
            "${pkgs.variety}/bin/variety"
            config.home.homeDirectory
          ]
          (builtins.readFile ../../dotfiles/autostart/variety.desktop)
      );
    in
    {
      home = {
        file = lib.mkMerge [
          (lib.mkIf cfg.enableDroid cfg.droid)
          (lib.mkIf cfg.enableEmacs cfg.emacs)
          (lib.mkIf cfg.enableMediaControl cfg.mediaControl)
          {
            ".local/share/bash-completion/completions/noctalia-shell".source =
              ../../scripts/completions/noctalia-shell-completions.sh;
            ".config/niri/config.kdl".source = ../../dotfiles/niri/config.kdl;
            ".config/autostart/variety.desktop".source = varietyAutostartDesktop;
            ".config/noctalia/settings.json".source = config.lib.file.mkOutOfStoreSymlink (
              config.home.homeDirectory + "/.config/home-manager/dotfiles/noctalia/settings.json"
            );
            ".config/noctalia/colors.json".source = config.lib.file.mkOutOfStoreSymlink (
              config.home.homeDirectory + "/.config/home-manager/dotfiles/noctalia/colors.json"
            );
            ".config/noctalia/plugins.json".source = config.lib.file.mkOutOfStoreSymlink (
              config.home.homeDirectory + "/.config/home-manager/dotfiles/noctalia/plugins.json"
            );
            ".config/vicinae/settings.json".source = config.lib.file.mkOutOfStoreSymlink (
              config.home.homeDirectory + "/.config/home-manager/dotfiles/vicinae/settings.json"
            );
          }
        ];

        sessionPath = [ "$HOME/.local/bin" ];
        sessionVariables = {
          MANPAGER = "sh -c '${pkgs.unixtools.col}/bin/col -bx | ${pkgs.bat}/bin/bat -l man -p'";
          NIX_BUILD_CORES = "$(( $(${pkgs.busybox}/bin/nproc) + 1 ) / 2 )";
          PAGER = "${pkgs.bat}/bin/bat -p";
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        };
      };
      fonts.fontconfig.enable = true;
    };
}
