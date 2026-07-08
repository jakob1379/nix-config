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
  btopRocm = pkgs.btop.override {
    rocmSupport = true;
  };
  # hermesAgent = inputs.hermes-agent.packages.${system}.default;
  # hermesAgentWithEspeak = pkgs.symlinkJoin {
  #   name = "hermes-agent-with-espeak-ng";
  #   paths = [ hermesAgent ];
  #   nativeBuildInputs = [ pkgs.makeWrapper ];
  #   postBuild = ''
  #     for bin in hermes hermes-agent hermes-acp; do
  #       wrapProgram "$out/bin/$bin" \
  #         --suffix PATH : ${lib.makeBinPath [ pkgs.espeak-ng ]}
  #     done
  #   '';
  # };
in
{
  customGit = {
    userName = "Jakob Stender Guldberg";
    userEmail = "jakob1379@gmail.com";
  };

  customPackages = {
    gui.enable = lib.mkForce true;
    core.packages = lib.mkForce (builtins.filter (p: p != pkgs.btop) packageSets.core);
  };

  home.packages = lib.mkAfter (
    with pkgs;
    [
      clockify
      adw-gtk3
      glab
      # hermesAgentWithEspeak
      coderabbit-cli
      btopRocm
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

  services.tailscale-systray.enable = false;

  customDotfiles = {
    enableMediaControl = true;
  };
}
