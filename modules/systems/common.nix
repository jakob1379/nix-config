{
  config,
  lib,
  pkgs,
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
  # customPackages.gui = []; # to disable gui packages
  #
  # Or disable a program like this:
  #
  # programs.tmux.enable = false;

  home.stateVersion = "24.05";
}
