{
  config,
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
    gui = config.customPackages.gui.enable;
  };

  btopRocm = pkgs.btop.override {
    rocmSupport = true;
  };
in
{
  customGit = {
    userName = "Jakob Stender Guldberg";
    userEmail = "jsg@seeqdx.com";
  };

  customPackages = {
    gui.enable = lib.mkForce true;
    core.packages = lib.mkForce (builtins.filter (p: p != pkgs.btop) packageSets.core);
  };

  home.packages = lib.mkAfter (
    with pkgs;
    [
      clockify
      slack
      adw-gtk3
      cachix
      glab
      solidcraft
      btopRocm
      teams-for-linux
      kdePackages.qt6ct
      libsForQt5.qt5ct
      nwg-look
    ]
  );

  home.file.".config/niri/config.kdl".source =
    let
      from = [
        ''layout "dk,dk,us"''
        ''variant "nodeadkeys,,"''
      ];
      shared = builtins.readFile ../../dotfiles/niri/config.kdl;
    in
    assert lib.assertMsg (lib.all (
      s: lib.hasInfix s shared
    ) from) "niri xkb lines changed: update the us override in home/systems/seeqdx-666.nix";
    lib.mkForce (
      pkgs.writeText "niri-config.kdl" (
        builtins.replaceStrings from [
          ''layout "us"''
          ''variant ""''
        ] shared
      )
    );
}
