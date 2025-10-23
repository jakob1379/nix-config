{
  pkgs,
  lib,
  config,
  ...
}:

{
  options.customDotfiles = {
    enableSsh = lib.mkEnableOption "SSH dotfiles";
    enableEmacs = lib.mkEnableOption "Emacs dotfiles";
    enableMediaControl = lib.mkEnableOption "media control dotfiles";

    ssh = lib.mkOption {
      type = lib.types.attrs;
      default = {
        ".ssh/keepassxc-prompt".source = ../../bin/keepassxc-prompt;
        ".ssh/config".source = ../../dotfiles/ssh/common;
      };
      description = "SSH dotfiles.";
    };
    emacs = lib.mkOption {
      type = lib.types.attrs;
      default = {
        ".emacs.d/config.org".source = ../../dotfiles/emacs/config.org;
        ".emacs.d/init.el".source = ../../dotfiles/emacs/init.el;
        ".local/share/bash-completion/completions/emacs".source = ../../dotfiles/emacs/emacs-completions.sh;
      };
      description = "Emacs dotfiles.";
    };
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
          (lib.mkIf cfg.enableMediaControl cfg.mediaControl)
        ];

        sessionPath = [ "$HOME/.local/bin" ];
        sessionVariables = {
          HISTCONTROL = "ignoreboth";
          LC_TIME = "en_GB.utf8";
          NIX_BUILD_CORES = "$(( $(${pkgs.busybox}/bin/nproc) / 2 < 1 ? 1 : $(${pkgs.busybox}/bin/nproc) / 2 ))";
          PAGER = "${pkgs.bat}/bin/bat -p";
        };
      };
      fonts.fontconfig.enable = true;
    };
}
