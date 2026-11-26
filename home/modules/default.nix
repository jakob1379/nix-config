{ inputs, ... }:

{
  imports = [
    inputs.agent-skills.homeManagerModules.default
    inputs.waytorandr.homeManagerModules.default
    ./dotfiles.nix
    ./packages.nix
    ./programs.nix
    ./services.nix
  ];
}
