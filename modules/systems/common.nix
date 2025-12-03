{
  lib,
  ...
}:

{
  # Common configuration for all systems
  imports = [ ../base ];

  nixpkgs.config.allowUnfree = true;
  programs.home-manager.enable = true;

  # The base modules already include core packages by default.
  # System-specific modules can override package sets if needed, for example:
  #
  # customPackages.enableGui = false;
  #
  # Or disable a program like this:
  #
  # programs.tmux.enable = false;

  # Enable package groups by default. Systems can override these settings.
  customPackages = {
    enableCore = lib.mkDefault true;
    enableDev = lib.mkDefault true;
    enableEmacs = lib.mkDefault true;
    enableScripts = lib.mkDefault true;
    enableGui = lib.mkDefault false; # GUI is opt-in per system
  };

  # Enable dotfile groups by default. Systems can override these.
  customDotfiles = {
    enableEmacs = lib.mkDefault true;
    enableDroid = lib.mkDefault true;
    enableMediaControl = lib.mkDefault false; # Opt-in per system
  };

  home.stateVersion = "24.05";
}
