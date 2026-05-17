{ lib, ... }:

{
  nixpkgs.config.allowUnfree = true;
  programs.home-manager.enable = true;

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
    enableMediaControl = lib.mkDefault false; # Opt-in per system
  };

  home.stateVersion = "24.05";
}
