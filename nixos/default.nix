{
  nixpkgs,
  inputs,
  lib,
  nixosModules,
}:
let
  desktopBaseModules = [
    nixosModules.nix-core
    nixosModules.locale-time
    nixosModules.networking
    nixosModules.desktop
    nixosModules.audio
    nixosModules.hardware-common
    nixosModules.virtualisation
    nixosModules.security
    nixosModules.printing
    nixosModules.boot
    nixosModules.user-jsg
  ];
in
{
  yoga = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = desktopBaseModules ++ [
      nixosModules.host-yoga
      {
        nixpkgs.config.allowUnfreePredicate = lib.allowUnfreePredicate;
      }
    ];
  };

  amd = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = desktopBaseModules ++ [
      nixosModules.host-amd
      {
        nixpkgs.config.allowUnfreePredicate = lib.allowUnfreePredicate;
      }
    ];
  };

  ku = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = desktopBaseModules ++ [
      nixosModules.host-ku
      {
        nixpkgs.config.allowUnfreePredicate = lib.allowUnfreePredicate;
      }
    ];
  };

  "vm-docker-main" = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      nixosModules.host-vm-docker-main
      {
        nixpkgs.config.allowUnfreePredicate = lib.allowUnfreePredicate;
      }
    ];
  };

}
