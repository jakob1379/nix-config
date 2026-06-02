{ inputs, ... }:
{
  system,
  username,
  homeDirectory,
  baseModules ? [ ],
  extraModules ? [ ],
  lib,
}:

inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfreePredicate = lib.allowUnfreePredicate;
    overlays = [ (import ../overlays/tana.nix) ];
  };
  modules = [
    {
      home.username = username;
      home.homeDirectory = homeDirectory;
    }
  ]
  ++ baseModules
  ++ extraModules;
  extraSpecialArgs = {
    inherit inputs system;
    flakeLib = lib;
  };
}
