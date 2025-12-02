{ inputs, ... }:

{
  system,
  username,
  homeDirectory,
  extraModules ? [ ],
  lib,
}:

inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfreePredicate = lib.allowUnfreePredicate;
  };
  modules = [
    # All systems import the common base configuration
    ../modules/systems/common.nix

    # Set user and home from arguments
    {
      home.username = username;
      home.homeDirectory = homeDirectory;
    }
  ]
  # And add their system-specific modules
  ++ extraModules;
  extraSpecialArgs = { inherit inputs system; };
}
