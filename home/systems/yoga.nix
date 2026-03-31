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
    gui.enable = lib.mkForce true;
    exclude = with pkgs; [ btop ];
    extra = lib.mkAfter (
      with pkgs;
      [
        (btop.override {
          cudaSupport = true;
        })
      ]
    );
  };

  customDotfiles = {
    enableMediaControl = true;
  };
}
