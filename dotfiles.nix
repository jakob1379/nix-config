{ pkgs, ... }:

let
  # Define each config section as a separate variable
  sshConfig = {
    ".ssh/keepassxc-prompt".source = ./bin/keepassxc-prompt;
    ".ssh/config".text = ''
      ProxyCommand $HOME/.ssh/keepassxc-prompt %h %p

      Include ~/.ssh/local_config

      Host *
        AddKeysToAgent yes'';
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
    LC_TIME = "en_GB.utf8";
    EDITOR = "emacsclient -c -n || emacs";
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
