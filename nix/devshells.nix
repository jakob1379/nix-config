{ lib }:
{ pkgs }:
let
  inherit (lib) generalPackages;
in {
  default = pkgs.mkShell {
    packages = generalPackages pkgs;
    buildInputs = with pkgs; [ pre-commit ];
    shellHook = ''
      if [ ! -f .git/hooks/pre-commit ]; then
        echo "Running pre-commit install for the first time..."
        pre-commit install
      fi
      export PS1="(dotfiles-shell 🫥) $PS1"
    '';
  };
}
