{ pkgs, system, inputs, ... }:
let
  username = "jga";
  packages = import ./packages.nix { inherit pkgs system inputs; };	
in
{
  home.username = "${username}";
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.05";

  nixpkgs.config.allowUnfree = true;

  programs.home-manager.enable = true;

  imports = [
    ./services.nix
    ./dotfiles.nix
  ];

  home.packages = packages.corePackages ++ packages.guiPackages ++ packages.devPackages ++ packages.customScripts ++ packages.emacsPackages;

}
