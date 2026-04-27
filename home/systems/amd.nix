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
      inputs.hermes-agent.packages.${system}.default
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
