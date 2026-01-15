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

    enableSsh = lib.mkEnableOption "SSH dotfiles";
    ssh = lib.mkOption {
      type = lib.types.attrs;
      default = {
        ".ssh/keepassxc-prompt".source = config.lib.file.mkOutOfStoreSymlink
          (config.home.homeDirectory + "/.config/home-manager/bin/keepassxc-prompt");
      };
      description = "SSH dotfiles.";
    };

    enableEmacs = lib.mkEnableOption "Emacs dotfiles";
    emacs = lib.mkOption {
      type = lib.types.attrs;
      default = {
        ".emacs.d/config.org".source = config.lib.file.mkOutOfStoreSymlink
          (config.home.homeDirectory + "/.config/home-manager/dotfiles/emacs/config.org");
        ".emacs.d/init.el".source = config.lib.file.mkOutOfStoreSymlink
          (config.home.homeDirectory + "/.config/home-manager/dotfiles/emacs/init.el");
        ".local/share/bash-completion/completions/emacs".source = config.lib.file.mkOutOfStoreSymlink
          (config.home.homeDirectory + "/.config/home-manager/dotfiles/emacs/emacs-completions.sh");
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
          (lib.mkIf cfg.enableSsh cfg.ssh)
          (lib.mkIf cfg.enableEmacs cfg.emacs)
          (lib.mkIf cfg.enableDroid cfg.droid)
          (lib.mkIf cfg.enableMediaControl cfg.mediaControl)
        ];

        sessionPath = [ "$HOME/.local/bin" ];
        sessionVariables = {
          MANPAGER = "sh -c '${pkgs.unixtools.col}/bin/col -bx | ${pkgs.bat}/bin/bat -l man -p'";
          HISTCONTROL = "ignoreboth";
          LC_TIME = "en_GB.utf8";
          NIX_BUILD_CORES = "$(( $(${pkgs.busybox}/bin/nproc) / 2 < 1 ? 1 : $(${pkgs.busybox}/bin/nproc) / 2 ))";
          PAGER = "${pkgs.bat}/bin/bat -p";
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        };
      };
      fonts.fontconfig.enable = true;
    };
}
