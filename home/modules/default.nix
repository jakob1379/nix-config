{ inputs, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
    inputs.waytorandr.homeManagerModules.default
    ./dotfiles.nix
    ./packages.nix
    ./programs.nix
    ./services.nix
  ];
}
