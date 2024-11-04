{
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}:
let
  # Import the exported lists from packages.nix
  packages = import ./packages.nix { inherit pkgs system inputs; };
  dotfiles = import ./dotfiles.nix { inherit pkgs; };

  sshConfigOverride = {
    ".ssh/config".text = ''
      Host *
        AddKeysToAgent yes
    '';
  };

  packagesToExclude = with pkgs; [
    texlive.combined.scheme-full
    texlivePackages.fontawesome5
  ];

  piPackages = lib.filter (pkg: !(lib.elem pkg packagesToExclude)) (
    packages.corePackages ++ packages.devPackages ++ packages.customScripts
  );
in
{
  home.username = "pi";
  home.homeDirectory = "/home/pi";

  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.packages = piPackages;

  home.file = sshConfigOverride // (dotfiles.emacsConfig // dotfiles.mediaConfig);

  home.sessionVariables = dotfiles.sessionVariables;

  programs.home-manager.enable = true;
  nixpkgs.config.allowUnfree = true;

  fonts = dotfiles.fontsConfig;
}
