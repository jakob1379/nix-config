{
  pkgs,
  ...
}:

{
  # Import all base modules. This was the missing piece.
  # By importing this, you make all the options and configurations
  # from the base modules available to this system.
  imports = [ ../base/default.nix ];

  # home.username and home.homeDirectory have been moved to flake.nix
  # to keep system-specific modules reusable.

  # Override git user and email for this system.
  customGit = {
    userName = "Jakob Stender Guldberg";
    userEmail = "jakob.aaes@darerl.com";
  };

  # System-specific overrides for UCPH machine
  customPackages = {
    enableGui = true; # Enable GUI packages for this desktop system

    # Add remmina package specifically for this system
    extra = with pkgs; [
      godot
      remmina
    ];
  };

  # Enable media control dotfiles for this system.
  customDotfiles = {
    enableMediaControl = true;
    enableAider = true;
  };
}
