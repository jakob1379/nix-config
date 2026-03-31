{
  lib,
  ...
}:

{
  imports = [ ./modules ];

  nixpkgs.config.allowUnfree = true;
  programs.home-manager.enable = true;

  # The base modules already include core package groups by default.
  # System-specific modules can override group sets if needed, for example:
  #
  # customPackages.gui.enable = false;
  #
  # Or disable a program like this:
  #
  # programs.tmux.enable = false;

  # Enable package groups by default. Systems can override these settings.
  customPackages = {
    core.enable = lib.mkDefault true;
    dev.enable = lib.mkDefault true;
    emacs.enable = lib.mkDefault true;
    scripts.enable = lib.mkDefault true;
    gui.enable = lib.mkDefault false; # GUI is opt-in per system
  };

  # Enable dotfile groups by default. Systems can override these.
  customDotfiles = {
    enableEmacs = lib.mkDefault true;
    enableDroid = lib.mkDefault true;
    enableMediaControl = lib.mkDefault false; # Opt-in per system
  };

  home.stateVersion = "24.05";
}
