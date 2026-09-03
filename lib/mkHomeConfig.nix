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
    "claude-code"
  ];
  config.allowUnfreePredicate = lib.allowUnfreePredicate;
  # legacyPackages would carry nixos-unstable-small's own config, dropping the
  # unfree predicate; re-import so both channels share it.
  smallPkgs = import inputs.nixpkgs-small { inherit system config; };
in
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import inputs.nixpkgs {
    inherit system config;
    overlays = [
      (import ../overlays/tana.nix)
      (_: _: inputs.nixpkgs.lib.getAttrs fromSmall smallPkgs)
      # Must come after fromSmall, which replaces t3code wholesale.
      (import ../overlays/t3code.nix smallPkgs)
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
