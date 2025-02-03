{ pkgs, ... }:

let
  # Define each config section as a separate variable
  sshConfig = {
    ".ssh/keepassxc-prompt".source = ./bin/keepassxc-prompt;
    ".ssh/config".source = ./dotfiles/ssh/common;
  };

  emacsConfig = {
    ".emacs.d/config.org".source = ./dotfiles/emacs/config.org;
    ".emacs.d/init.el".source = ./dotfiles/emacs/init.el;
  };

  mediaConfig = {
    ".config/pipewire/media-session.d/bluez-monitor.conf".text = ''
      properties = {
        bluez5.msbc-support = true;
      }
    '';
  };

  # Session variables configuration

  sessionVariables = {
    PAGER = "${pkgs.bat}/bin/bat -p";
    MANPAGER = "bat -pl man";
    EDITOR = ''emacsclient --create-frame --alternate-editor emacs'';
    LC_TIME = "en_GB.utf8";
    QT_QPA_PLATFORM = "wayland";
    HISTCONTROL = "ignoreboth";
    NB_CONFIG = /var/lib/netbird/config.json;

    NIX_BUILD_CORES = "$(( $(nproc) / 2 < 1 ? 1 : $(nproc) / 2 ))";
  };

  # Fonts configuration
  fontsConfig = {
    fontconfig.enable = true;
  };

in
{
  inherit
    emacsConfig
    mediaConfig
    sshConfig
    sessionVariables
    fontsConfig
    ;
}
