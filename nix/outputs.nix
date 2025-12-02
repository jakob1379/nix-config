inputs@{ nixpkgs, ... }:
let
  lib = import ./lib.nix { inherit nixpkgs inputs; };
  inherit (lib) forAllSystems;
in
{
  homeConfigurations = import ./home-configurations.nix { inherit lib; };
  nixosConfigurations = import ./nixos-configurations.nix { inherit nixpkgs inputs lib; };
  devShells = forAllSystems (pkgs: (import ./devshells.nix { inherit lib pkgs; }));
}
