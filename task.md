find all writeshellscripts a and convert them to writeShellApplication as that
include proper dependencies and not the sideeffect I have implemented in many
places that might be cleaned up in the nix store by using
"${nixpkgs.<some_package>}/bin/<the bin>". Make a branch and pr for each
separate shell application you make.
https://nixos.org/manual/nixpkgs/stable/#trivial-builder-writeShellApplication.
Make sure each PR is only concerning a single writeshellapplication change and
not multiple, update any existing PR if need be

make sure to use ag instead of grep.
