{
  pkgs,
  lib,
  system,
  ...
}:

let
  packageSets = import ../modules/package-sets.nix { inherit pkgs lib system; };
in
{
  customGit = {
    userName = "Jakob Stender Guldberg";
    userEmail = "jakob1379@gmail.com";
  };

  customPackages = {
    gui.enable = lib.mkForce true;
    core.packages = lib.mkForce (
      builtins.map (
        p:
        if p == pkgs.btop then
          pkgs.btop.override {
            cudaSupport = true;
          }
        else
          p
      ) packageSets.core
    );
  };

  customDotfiles = {
    enableMediaControl = true;
  };
}
