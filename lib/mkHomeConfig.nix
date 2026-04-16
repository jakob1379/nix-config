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
    overlays = [ inputs.self.overlays.default ];
  };
  modules = [
    ../home/common.nix
    {
      home.username = username;
      home.homeDirectory = homeDirectory;
    }
  ]
  ++ extraModules;
  extraSpecialArgs = { inherit inputs system; };
}
