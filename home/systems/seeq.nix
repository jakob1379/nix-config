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

  programs = {
    codex = {
      enable = true;
    };
  };

  home.packages = lib.mkAfter (
    with pkgs;
    [
      glab
    ]
  );

  customSsh.enableKeepassxc = lib.mkForce false;

  customPackages.dev.packages = lib.mkAfter (with pkgs; [ glab ]);
}
