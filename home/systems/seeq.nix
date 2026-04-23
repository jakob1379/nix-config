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

    emacs.package = lib.mkForce pkgs.emacs-nox;
  };

  services.emacs = {
    enable = lib.mkForce true;
    package = lib.mkForce pkgs.emacs-nox;
    startWithUserSession = lib.mkForce true;
    socketActivation.enable = lib.mkForce false;
    defaultEditor = lib.mkForce false;
    client.enable = lib.mkForce false;
  };

  home = {
    shellAliases.ec = ''emacsclient -t --alternate-editor ""'';
    sessionVariables = {
      EDITOR = "emacsclient -t";
      VISUAL = "emacsclient -t";
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
