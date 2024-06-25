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
    ".ssh/config".text = ''
      ProxyCommand $HOME/.ssh/keepassxc-prompt %h %p

      Host rpi
          HostName 192.168.8.114
   '';
  };

  home.sessionVariables = {
    EDITOR = "emacsclient";
    PAGER = "bat -p";
    MANPAGER = "bat -pl ma";
  };

  fonts.fontconfig.enable = true;
}
