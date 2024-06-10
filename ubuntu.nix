{ config, lib, pkgs, ... }:

let
  cliPackages = with pkgs; [
  ];

  guiPackages = with pkgs; [
    gnome.gnome-tweaks
  ];

in
{
  home.packages = cliPackages ++ guiPackages;
}
