{ inputs, ... }:

{
  flake.modules.homeManager = {
    waytorandr = inputs.waytorandr.homeManagerModules.default;
    common = ../../modules/home/common.nix;
    packages = ../../modules/home/packages.nix;
    dotfiles = ../../modules/home/dotfiles.nix;
    git-ssh = ../../modules/home/git-ssh.nix;
    shell-cli = ../../modules/home/shell-cli.nix;
    dev-ai = ../../modules/home/dev-ai.nix;
    desktop-apps = ../../modules/home/desktop-apps.nix;
    home-storage = ../../modules/home/home-storage.nix;
    home-wallpaper = ../../modules/home/home-wallpaper.nix;
    home-niri-desktop = ../../modules/home/home-niri-desktop.nix;
    home-session-services = ../../modules/home/home-session-services.nix;
    host-amd = ../../modules/home/hosts/amd.nix;
    host-pi = ../../modules/home/hosts/pi.nix;
    host-seeq = ../../modules/home/hosts/seeq.nix;
    host-yoga = ../../modules/home/hosts/yoga.nix;
  };
}
