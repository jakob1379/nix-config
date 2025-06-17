{ config, lib, pkgs, ... }:

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
    # Add remmina package specifically for this system
    extra = [ pkgs.remmina ];
  };

  # NOTE: The 'customDotfiles' option is likely defined in a 'modules/base/dotfiles.nix'
  # file that I haven't seen. I've commented this out to prevent errors.
  # Please provide that file if you want to re-enable this.
  # customDotfiles.mediaControl.enable = true;
}
