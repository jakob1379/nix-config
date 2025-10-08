{ nixpkgs, inputs }:
{
  ku = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ../nixos/ku/configuration.nix
      ../nixos/yoga/configuration.nix
    ];
  };
}
