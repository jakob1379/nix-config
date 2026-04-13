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
      {
        nixpkgs.config.allowUnfreePredicate = lib.allowUnfreePredicate;
        nixpkgs.overlays = [ inputs.self.overlays.default ];
      }
    ];
  };

  amd = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./hosts/amd
      {
        nixpkgs.config.allowUnfreePredicate = lib.allowUnfreePredicate;
        nixpkgs.overlays = [ inputs.self.overlays.default ];
      }
    ];
  };

  ku = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./hosts/ku
      {
        nixpkgs.config.allowUnfreePredicate = lib.allowUnfreePredicate;
        nixpkgs.overlays = [ inputs.self.overlays.default ];
      }
    ];
  };

  "vm-docker-main" = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./hosts/vm/base.nix
      {
        nixpkgs.config.allowUnfreePredicate = lib.allowUnfreePredicate;
        nixpkgs.overlays = [ inputs.self.overlays.default ];
      }
    ];
  };

}
