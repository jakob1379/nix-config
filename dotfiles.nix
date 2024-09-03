{ pkgs, ... }:

let
  # Define each config section as a separate variable
  sshConfig = {
    ".ssh/keepassxc-prompt".source = ./bin/keepassxc-prompt;
    ".ssh/config".text = ''
  ProxyCommand $HOME/.ssh/keepassxc-prompt %h %p

  Host *
    AddKeysToAgent yes

  Host rpi
    HostName 192.168.8.114'';
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
  };

  # Fonts configuration
  fontsConfig = {
    fontconfig.enable = true;
  };

in
{
  # Export for possible overriding
  inherit sshConfig emacsConfig mediaConfig sessionVariables fontsConfig;

  # Combine all configs into `home.file`
  home.file = sshConfig // emacsConfig // mediaConfig;

  # Use separate configurations
  home.sessionVariables = sessionVariables;
  fonts = fontsConfig;
}
