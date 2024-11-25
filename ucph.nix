{
  pkgs,
  system,
  inputs,
  lib,
  ...
}:
let
  username = "jga";

  # Import the exported lists from packages.nix
  packages = import ./packages.nix { inherit pkgs system lib inputs; };
  dotfiles = import ./dotfiles.nix { inherit pkgs; };
in
{
  home.username = "${username}";
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.05";

  nixpkgs.config.allowUnfree = true;
  
  programs.home-manager.enable = true;

  # Correct usage of home.file
  home.file = dotfiles.emacsConfig // dotfiles.mediaConfig // dotfiles.sshConfig;

  home.packages =
    packages.corePackages
    ++ packages.devPackages
    ++ packages.guiPackages
    ++ packages.customScripts
    ++ packages.emacsPackages;

  # Include session variables from dotfiles.nix
  home.sessionVariables = dotfiles.sessionVariables;

  # Fonts configuration if required
  fonts = dotfiles.fontsConfig;

}
