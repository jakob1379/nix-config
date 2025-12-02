{
  nixpkgs,
  inputs,
  lib,
}:
{
  yoga = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ../nixos/yoga/configuration.nix
      { nixpkgs.config.allowUnfreePredicate = lib.allowUnfreePredicate; }
    ];
  };

  amd = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ../nixos/amd/configuration.nix
      { nixpkgs.config.allowUnfreePredicate = lib.allowUnfreePredicate; }
    ];
  };

}
