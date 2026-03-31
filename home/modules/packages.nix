{
  pkgs,
  lib,
  config,
  system,
  ...
}:

let
  packageSets = import ./package-sets.nix { inherit pkgs lib system; };
in
{
  options.customPackages = {
    core = {
      enable = lib.mkEnableOption "core packages";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = packageSets.core;
        description = "Core packages.";
      };
    };

    gui = {
      enable = lib.mkEnableOption "GUI packages";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = packageSets.gui;
        description = "GUI packages.";
      };
    };

    dev = {
      enable = lib.mkEnableOption "development packages";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = packageSets.dev;
        description = "Development packages.";
      };
    };

    emacs = {
      enable = lib.mkEnableOption "Emacs packages";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = packageSets.emacs;
        description = "Emacs packages.";
      };
    };

    scripts = {
      enable = lib.mkEnableOption "custom scripts";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = packageSets.scripts;
        description = "Custom script packages.";
      };
    };
  };

  config =
    let
      cfg = config.customPackages;
    in
    {
      home.packages =
        (lib.optionals cfg.core.enable cfg.core.packages)
        ++ (lib.optionals cfg.gui.enable cfg.gui.packages)
        ++ (lib.optionals cfg.dev.enable cfg.dev.packages)
        ++ (lib.optionals cfg.emacs.enable cfg.emacs.packages)
        ++ (lib.optionals cfg.scripts.enable cfg.scripts.packages);
    };
}
