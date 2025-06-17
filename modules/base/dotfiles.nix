{ pkgs, lib, config, ... }:

{
  options.customDotfiles = {
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

  config = {
    home.file = lib.mkMerge [
      config.customDotfiles.ssh
      config.customDotfiles.emacs
      config.customDotfiles.mediaControl
    ];

    home.sessionVariables = {
      HISTCONTROL = "ignoreboth";
      LC_TIME = "en_GB.utf8";
      MANPAGER = "bat -pl man";
      NIX_BUILD_CORES = "$(( $(nproc) / 2 < 1 ? 1 : $(nproc) / 2 ))";
      PAGER = "${pkgs.bat}/bin/bat -p";
      HOARDER_SERVER_ADDR = "https://hoarder.jgalabs.dk";
      AIDER_CHECK_UPDATE = "false";
      AIDER_ANALYTICS = "false";
    };

    fonts.fontconfig.enable = true;
  };
}
