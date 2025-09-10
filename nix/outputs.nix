# This file reassembles the original outputs without changes.
inputs@{ nixpkgs, ... }:
let
  lib = import ./lib.nix { inherit nixpkgs inputs; };
  inherit (lib) mkHomeConfig forAllSystems generalPackages;
  homeConfigurations = import ./home-configurations.nix { lib = lib; };
  nixosConfigurations = import ./nixos-configurations.nix { inherit nixpkgs inputs; };
  devShellsFor = import ./devshells.nix { lib = lib; };
in {
  inherit nixosConfigurations;
  homeConfigurations = homeConfigurations;
  devShells = forAllSystems (pkgs: devShellsFor { inherit pkgs; });
}
