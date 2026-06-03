{
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
  };
  btopCuda = pkgs.btop.override {
    cudaSupport = true;
  };
in
{
  customGit = {
    userName = "Jakob Stender Guldberg";
    userEmail = "jakob1379@gmail.com";
  };

  customPackages = {
    gui.enable = lib.mkForce true;
    core.packages = lib.mkForce (builtins.filter (p: p != pkgs.btop) packageSets.core);
  };

  home.packages = lib.mkAfter [ btopCuda ];

  customDotfiles = {
    enableMediaControl = true;
  };
}
