{
  config,
  pkgs,
  lib,
  ...
}:

let
  coreServices = {
    emacs = {
      package = pkgs.emacs-pgtk;
      startWithUserSession = false;
      enable = true;
      defaultEditor = true;
      client.arguments = [
        "--alternative-editor ''"
        "--reuse-frame"
        "--no-wait"
      ];
    };

    cachix-agent = {

    };

    gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-gtk2;
      pinentry.program = "pinentry-gtk-2";
    };

    ssh-agent = {
      enable = true;
    };

    home-manager.autoExpire.enable = true;
  };

  guiServices = {
    udiskie = {
      enable = true;
      tray = "auto";
    };

    unclutter = {
      enable = true;
      timeout = 5;
    };

    waytorandr = {
      enable = true;
    };

    easyeffects.enable = true;
    mpris-proxy.enable = true;
  };
in
{
  config = {
    systemd.user.startServices = true;
    services = coreServices // lib.optionalAttrs config.customPackages.gui.enable guiServices;
  };
}
