{ lib, pkgs }:
let
  inherit (lib) generalPackages;
in
{
  default = pkgs.mkShell {
    packages = generalPackages pkgs;
    buildInputs = with pkgs; [ pre-commit ];
    shellHook = ''
      export SSL_CERT_FILE=$(pkgs.cacert)/etc/ssl/certs/ca-bundle.crt
      if [ ! -f .git/hooks/pre-commit ]; then
        echo "Running pre-commit install for the first time..."
        prek install
      fi
      export PS1="(dotfiles-shell 🫥) $PS1"
    '';
  };
}
