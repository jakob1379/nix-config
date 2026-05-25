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

  coderabbit-cli = inputs.numtide-llm-agents.packages.${system}.coderabbit-cli;
  hermesAgent = inputs.hermes-agent.packages.${system}.default;
  hermesAgentWithEspeak = pkgs.symlinkJoin {
    name = "hermes-agent-with-espeak-ng";
    paths = [ hermesAgent ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in hermes hermes-agent hermes-acp; do
        wrapProgram "$out/bin/$bin" \
          --suffix PATH : ${lib.makeBinPath [ pkgs.espeak-ng ]}
      done
    '';
  };
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
            rocmSupport = true;
          }
        else
          p
      ) packageSets.core
    );
  };

  home.packages = lib.mkAfter (
    with pkgs;
    [
      clockify
      adw-gtk3
      glab
      hermesAgentWithEspeak
      coderabbit-cli
      # teams-for-linux
      kdePackages.qt6ct
      libsForQt5.qt5ct
      nwg-look
    ]
  );

  programs = {
    codex = {
      enable = true;
    };
  };

  services.tailscale-systray.enable = true;

  customDotfiles = {
    enableMediaControl = true;
  };
}
