{ ... }:
let
  username = "jga";
in
{
  home.username = "${username}";
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "22.11";

  nixpkgs.config.allowUnfree = true;

  programs.home-manager.enable = true;
}
