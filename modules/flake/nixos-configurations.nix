{ config, inputs, ... }:

{
  flake.nixosConfigurations = import ../../nixos {
    nixpkgs = inputs.nixpkgs;
    inherit inputs;
    lib = config.flake.lib;
    nixosModules = config.flake.modules.nixos;
  };
}
