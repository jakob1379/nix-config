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
    PAGER = "bat -p";
    MANPAGER = "bat -pl man";
    EDITOR = ''emacsclient --create-frame --alternate-editor="" --no-wait'';
    LC_TIME = "en_GB.utf8";
    QT_QPA_PLATFORM = "wayland";
    HISTCONTROL = "ignoreboth";
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
