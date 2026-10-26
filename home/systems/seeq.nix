{
  config,
  pkgs,
  lib,
  system,
  inputs,
  ...
}:

let
  packageSets = import ../modules/package-sets.nix {
    inherit
      pkgs
      lib
      system
      inputs
      ;
    gui = config.customPackages.gui.enable;
  };

in
{
  customGit = {
    userName = "Jakob Stender Guldberg";
    userEmail = "jakob1379@gmail.com";
  };

  customPackages = {
    gui.enable = lib.mkForce false;
    core.packages = lib.mkForce (builtins.filter (p: p != pkgs.btop) packageSets.core);
  };

  home.packages = lib.mkAfter (
    with pkgs;
    [
      cachix
      glab
      btop-cuda
    ]
  );

  customDotfiles = {
    enableMediaControl = true;
  };
}
