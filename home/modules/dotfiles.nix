{
  pkgs,
  lib,
  config,
  ...
}:

{
  options.customDotfiles = {
    enableEmacs = lib.mkEnableOption "Emacs dotfiles";
    emacs = lib.mkOption {
      type = lib.types.attrs;
      default = {
        ".emacs.d/config.org".source = ../../dotfiles/emacs/config.org;
        ".emacs.d/config.el" = {
          source = "${pkgs.callPackage ../../nix/emacs-config-el.nix { }}/config.el";
          force = true;
        };
        ".emacs.d/early-init.el".source = ../../dotfiles/emacs/early-init.el;
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
    in
    {
      home = {
        file = lib.mkMerge [
          (lib.mkIf cfg.enableEmacs cfg.emacs)
          (lib.mkIf cfg.enableMediaControl cfg.mediaControl)
          (lib.mkIf config.customPackages.gui.enable {
            ".local/share/bash-completion/completions/noctalia".source =
              ../../scripts/completions/noctalia-completions.sh;
          })
          {
            ".config/niri/config.kdl".source = ../../dotfiles/niri/config.kdl;
            ".config/vicinae/settings.json".source = config.lib.file.mkOutOfStoreSymlink (
              config.home.homeDirectory + "/.config/home-manager/dotfiles/vicinae/settings.json"
            );
          }
        ];

        sessionPath = [ "$HOME/.local/bin" ];
        sessionVariables = {
          MANPAGER = "${pkgs.bat}/bin/bat -l man -p'";
          NIX_BUILD_CORES = "$(${pkgs.busybox}/bin/nproc --ignore=1)";
          PAGER = "${pkgs.bat}/bin/bat -p";
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        };
      };
      fonts.fontconfig.enable = true;
    };
}
