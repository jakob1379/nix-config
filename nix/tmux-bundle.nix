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
    if grep -n /nix/store $out/tmux.conf; then
      echo "tmux.conf still references the Nix store" >&2
      exit 1
    fi

    cp ${pkgs.pkgsStatic.tmux}/bin/tmux $out/bin/tmux
    cp ${../scripts/tmux/host-color.sh} $out/bin/tmux-host-color
    cp ${../scripts/tmux/window-label.sh} $out/bin/tmux-window-label
    cp ${../scripts/tmux/net-status.sh} $out/bin/tmux-net-status
    chmod +x $out/bin/*
    cp -r ${dotbar}/share/tmux-plugins/dotbar $out/plugins/dotbar
    cp -r ${pkgs.ncurses}/share/terminfo $out/share/terminfo

    cat > $out/env.sh <<'SH'
    export PATH="${prefix}/bin:$PATH"
    export TERMINFO_DIRS="${prefix}/share/terminfo:/usr/share/terminfo"
    SH
  ''
