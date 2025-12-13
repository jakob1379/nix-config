{ pkgs, lib, inputs, ... }:

{
  # Import all base modules. This was the missing piece.
  # By importing this, you make all the options and configurations
  # from the base modules available to this system.
  imports = [ ../base/default.nix ];

  # home.username and home.homeDirectory have been moved to flake.nix
  # to keep system-specific modules reusable.

  # Note: Plasma is set as the default session in nixos/amd/configuration.nix
  # This niri configuration is available when starting niri manually or via SDDM
  # (if niri desktop entry is installed). Plasma native lockscreen will be used
  # when using the plasma session.

  # Override git user and email for this system.
  customGit = {
    userName = "Jakob Stender Guldberg";
    userEmail = "jakob1379@gmail.com";
  };

  # System-specific overrides for UCPH machine
  customPackages = {
    enableGui = lib.mkForce true; # Enable GUI packages for this desktop system
    # Add remmina package specifically for this system
    extra = with pkgs; [
      clockify
      # niri-related packages
      waybar
      swaybg
      mako
      rofi
      wl-clipboard
      networkmanagerapplet
      kdePackages.polkit-kde-agent-1
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
      xwayland-satellite
      fuzzel
    ];
  };

  # Enable media control dotfiles for this system.
  customDotfiles = { enableMediaControl = true; };

  # Override gnome-keyring for niri
  services.gnome-keyring.enable = lib.mkForce true;

  # Niri configuration
  programs.niri = {
    enable = true;
    settings = {
      spawn-at-startup = [
        { command = [ "${lib.getExe pkgs.waybar}" ]; }
        { command = [ "${lib.getExe pkgs.networkmanagerapplet}" ]; }
        {
          command = [
            "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"
          ];
        }
        { command = [ "${lib.getExe pkgs.wl-clipboard}" ]; }
      ];
      input.keyboard.xkb.layout = "dk";
      layout.gaps = 6;
      layout.border.enable = true;
      layout.border.width = 1;
      layout.border.active.color = "#ffffff";
      layout.border.inactive.color = "#666666";
      
      # Override terminal bind to use XDG default terminal (ghostty)
      binds = {
        "Mod+T" = {
          action = "spawn";
          argv = [ "xdg-terminal-exec" ];
          hotkey-overlay-title = "Open a Terminal: ghostty";
        };
      };
    };
  };
}
