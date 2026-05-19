{ ... }:

{
  flake.modules.nixos = {
    nix-core = ../../modules/nixos/nix-core.nix;
    locale-time = ../../modules/nixos/locale-time.nix;
    networking = ../../modules/nixos/networking.nix;
    desktop = ../../modules/nixos/desktop.nix;
    audio = ../../modules/nixos/audio.nix;
    hardware-common = ../../modules/nixos/hardware-common.nix;
    virtualisation = ../../modules/nixos/virtualisation.nix;
    security = ../../modules/nixos/security.nix;
    printing = ../../modules/nixos/printing.nix;
    boot = ../../modules/nixos/boot.nix;
    user-jsg = ../../nixos/users/jsg.nix;
    host-amd = ../../nixos/hosts/amd;
    host-ku = ../../nixos/hosts/ku;
    host-vm-docker-main = ../../nixos/hosts/vm/base.nix;
    host-yoga = ../../nixos/hosts/yoga;
  };
}
