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
in
{
  # Import common configurations
  imports = [
    ./home.nix
    ./services.nix
  ];

  # Override user-specific configurations
  home.username = lib.mkForce "pi";
  home.homeDirectory = lib.mkForce "/home/pi";
  home.stateVersion = lib.mkForce "24.05";

  # Override to not include gui packages
  home.packages =
    packages.corePackages ++ packages.devPackages ++ packages.customScripts ++ packages.emacsPackages;

  # Override the `sshConfig`
  home.file = sshConfigOverride // (dotfiles.emacsConfig // dotfiles.mediaConfig);
}
