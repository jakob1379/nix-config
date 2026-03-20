{
  pkgs,
  lib,
  ...
}:

{
  imports = [ ../base/default.nix ];

  customGit = {
    userName = "Jakob Stender Guldberg";
    userEmail = "jakob1379@gmail.com";
  };

  customSsh.enableKeepassxc = lib.mkForce false;

  customPackages = {
    extra = with pkgs; [
      glab
    ];
  };
}
