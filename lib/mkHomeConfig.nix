{ inputs, ... }:
{
  system,
  username,
  homeDirectory,
  extraModules ? [ ],
  lib,
}:

let
  # packages tracked on nixos-unstable-small instead of nixos-unstable
  fromSmall = [
    "t3code"
  ];
in
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfreePredicate = lib.allowUnfreePredicate;
    overlays = [
      (import ../overlays/tana.nix)
      (_: _: inputs.nixpkgs.lib.getAttrs fromSmall inputs.nixpkgs-small.legacyPackages.${system})
    ];
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
