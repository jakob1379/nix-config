{
  pkgs,
  lib,
  inputs,
  system,
  ...
}:
let
  coderabbit-cli = inputs.numtide-llm-agents.packages.${system}.coderabbit-cli;
in
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
    sessionVariables = {
      EDITOR = "emacsclient -t";
      VISUAL = "emacsclient -t";
    };
  };

  home.packages = lib.mkAfter (
    with pkgs;
    [
      coderabbit-cli
      glab
    ]
  );

  customSsh.enableKeepassxc = lib.mkForce false;

}
