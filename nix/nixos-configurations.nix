{ nixpkgs, inputs }:
{
  ku = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ../nixos/ku/configuration.nix
    ];
  };

  yoga = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ../nixos/yoga/configuration.nix
    ];
  };
}
