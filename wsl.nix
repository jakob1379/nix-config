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
  packages = import ./packages.nix { inherit pkgs system lib; };
  dotfiles = import ./dotfiles.nix { inherit pkgs lib; };

  sshConfigOverride = {
    ".ssh/config".text = ''
      Include ~/.ssh/conf.d/local_config

      Host *
          AddKeysToAgent yes

          # SSH multiplexing to speed up connections
          ControlMaster auto
          ControlPath ~/.ssh/sockets/%r@%h-%p
          ControlPersist yes
    '';
  };
in
{
  # allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Override user-specific configurations
  home.username = "fuzie";
  home.homeDirectory = "/home/fuzie";
  home.stateVersion = "24.05";

  # Override to not include gui packages
  home.packages =
    packages.corePackages ++ packages.devPackages ++ packages.customScripts ++ packages.emacsPackages;

  # Override the `sshConfig`
  home.file = sshConfigOverride // (dotfiles.emacsConfig // dotfiles.mediaConfig);

  programs.home-manager.enable = true;

  home.sessionVariables = dotfiles.sessionVariables;

}
