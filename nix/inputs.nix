{
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-utils.url = "github:numtide/flake-utils";
  nixgl.url = "github:nix-community/nixGL";
  zen-browser.url = "github:youwen5/zen-browser-flake";
}
