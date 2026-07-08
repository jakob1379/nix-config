{
  emacs-nox,
  runCommand,
}:

runCommand "emacs-config-el"
  {
    nativeBuildInputs = [ emacs-nox ];
  }
  ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME/.emacs.d" "$out"

    cp ${../dotfiles/emacs/config.org} "$HOME/.emacs.d/config.org"

    emacs -Q --batch --eval "(progn (require 'org) (require 'ob-tangle) (org-babel-tangle-file \"$HOME/.emacs.d/config.org\"))"
    cp "$HOME/.emacs.d/config.el" "$out/config.el"
  ''
