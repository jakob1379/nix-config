{ pkgs, ... }:

{
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;
    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';

    ".ssh/keepassxc-prompt".source = ./bin/keepassxc-prompt;
    ".ssh/config".text = builtins.readFile ./dotfiles/ssh/config;
    ".config/pipewire/media-session.d/bluez-monitor.conf".text = ''
    properties = {
      bluez5.msbc-support = true
    }
    '';
  };

  home.sessionVariables = {
    EDITOR = "emacsclient";
    PAGER = "bat -p";
    MANPAGER = "bat -pl man";
    LC_TIME = "en_GB.utf8";
  };

  fonts.fontconfig.enable = true;
}
