{ config, inputs, ... }:

{
  flake.nixosConfigurations = import ../../nixos {
    inherit (inputs) nixpkgs;
    inherit inputs;
    lib = config.flake.lib;
    nixosModules = config.flake.modules.nixos;
  };
}
