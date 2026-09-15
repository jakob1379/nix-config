{
  pkgs,
  lib,
  inputs,
  system,
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

  coderabbit-cli = inputs.numtide-llm-agents.packages.${system}.coderabbit-cli;
  btopCudaWsl = pkgs.symlinkJoin {
    name = "btop-cuda-wsl";
    paths = [ pkgs.btop-cuda ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/btop \
        --prefix LD_LIBRARY_PATH : /usr/lib/wsl/lib
    '';
  };
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

    emacs.package = lib.mkForce pkgs.emacs31-nox;
  };

  services.emacs = {
    enable = lib.mkForce true;
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
      btopCudaWsl
    ]
  );

  customPackages = {
    core.packages = lib.mkForce (builtins.filter (p: p != pkgs.btop) packageSets.core);
  };

  customSsh.enableKeepassxc = lib.mkForce false;

}
