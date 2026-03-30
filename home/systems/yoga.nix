{
  pkgs,
  lib,
  ...
}:

{
  customGit = {
    userName = "Jakob Stender Guldberg";
    userEmail = "jakob1379@gmail.com";
  };

  customPackages = {
    enableGui = lib.mkForce true;
    exclude = with pkgs; [ btop ];
    extra = with pkgs; [
      (btop.override {
        cudaSupport = true;
      })
    ];
  };

  customDotfiles = {
    enableMediaControl = true;
  };
}
