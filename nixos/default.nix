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
      ./hosts/yoga
      { nixpkgs.config.allowUnfreePredicate = lib.allowUnfreePredicate; }
    ];
  };

  amd = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./hosts/amd
      { nixpkgs.config.allowUnfreePredicate = lib.allowUnfreePredicate; }
    ];
  };

  ku = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./hosts/ku
      { nixpkgs.config.allowUnfreePredicate = lib.allowUnfreePredicate; }
    ];
  };

}
