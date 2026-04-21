{ inputs, ... }:

{
  imports = [
    inputs.nix-index-database.homeModules.default
    inputs.waytorandr.homeManagerModules.default
    ./dotfiles.nix
    ./packages.nix
    ./programs.nix
    ./services.nix
  ];
}
