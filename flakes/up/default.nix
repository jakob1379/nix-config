let
  flake = import ./.;
in
flake.packages.${builtins.currentSystem}.default
