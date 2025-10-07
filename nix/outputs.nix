# This file reassembles the original outputs without changes.
inputs@{ nixpkgs, ... }:
let
  lib = import ./lib.nix { inherit nixpkgs inputs; };
  inherit (lib) forAllSystems;
  homeConfigurations = import ./home-configurations.nix { inherit lib; };
  nixosConfigurations = import ./nixos-configurations.nix { inherit nixpkgs inputs; };
  devShellsFor = import ./devshells.nix { inherit lib; };
in
{
  inherit nixosConfigurations;
  inherit homeConfigurations;
  devShells = forAllSystems (pkgs: devShellsFor { inherit pkgs; });
}
