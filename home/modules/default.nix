{ inputs, ... }:

{
  imports = [
    inputs.waytorandr.homeManagerModules.default
    ./dotfiles.nix
    ./packages.nix
    ./programs.nix
    ./services.nix
  ];
}
