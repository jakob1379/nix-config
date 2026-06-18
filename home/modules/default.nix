{ inputs, ... }:

{
  imports = [
    inputs.waytorandr.homeManagerModules.default
    inputs.open-design.homeManagerModules.default
    ./dotfiles.nix
    ./packages.nix
    ./programs.nix
    ./services.nix
  ];
}
