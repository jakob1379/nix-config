{
  description = "Home Manager configuration of jga";

  inputs = import ./nix/inputs.nix;

  outputs = inputs@{ nixpkgs, ... }: (import ./nix/outputs.nix) inputs;
}
