{ hm }:
let
  inherit (hm) pkgs config;
  scripts = import ./tmux-scripts.nix { inherit pkgs; };
  inherit (pkgs.tmuxPlugins) dotbar;
  prefix = "$HOME/.local/tmux";
  conf =
    builtins.replaceStrings
      [
        "${scripts.hostColor}/bin"
        "${scripts.windowLabel}/bin"
        "${scripts.netStatus}/bin"
        "${dotbar}/share/tmux-plugins"
      ]
      [
        "${prefix}/bin"
        "${prefix}/bin"
        "${prefix}/bin"
        "${prefix}/plugins"
      ]
      config.xdg.configFile."tmux/tmux.conf".text;
in
pkgs.runCommand "tmux-bundle"
  {
    inherit conf;
    passAsFile = [ "conf" ];
  }
  ''
    mkdir -p $out/bin $out/plugins $out/share
    cp $confPath $out/tmux.conf
    cp ${pkgs.pkgsStatic.tmux}/bin/tmux $out/bin/tmux
    cp ${../scripts/tmux/host-color.sh} $out/bin/tmux-host-color
    cp ${../scripts/tmux/window-label.sh} $out/bin/tmux-window-label
    cp ${../scripts/tmux/net-status.sh} $out/bin/tmux-net-status
    cp -r ${dotbar}/share/tmux-plugins/dotbar $out/plugins/dotbar
    cp -r --no-preserve=mode ${pkgs.ncurses}/share/terminfo $out/share/terminfo
    cp -r --no-preserve=mode ${pkgs.kitty.terminfo}/share/terminfo/. $out/share/terminfo/

    for entry in t/tmux-256color x/xterm-kitty; do
      test -e $out/share/terminfo/$entry || { echo "missing terminfo $entry" >&2; exit 1; }
    done
    grep -o '[$]HOME/[.]local/tmux/[[:alnum:]/._-]*' $out/tmux.conf | while read -r ref; do
      test -e "$out/''${ref#*/.local/tmux/}" || { echo "tmux.conf references missing $ref" >&2; exit 1; }
    done

    cat > $out/env.sh <<'SH'
    export PATH="${prefix}/bin:$PATH"
    export TERMINFO_DIRS="${prefix}/share/terminfo:''${TERMINFO_DIRS:-/usr/share/terminfo}"
    SH

    if grep -rn /nix/store $out/tmux.conf $out/env.sh $out/bin/tmux-* $out/plugins; then
      echo "bundle still references the Nix store" >&2
      exit 1
    fi
  ''
