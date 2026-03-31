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

  customSsh.enableKeepassxc = lib.mkForce false;

  customPackages.dev.packages = lib.mkAfter (with pkgs; [ glab ]);
}
