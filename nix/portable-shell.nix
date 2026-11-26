{ hm }:
let
  inherit (hm) pkgs config;
  inherit (pkgs) lib;
  scripts = import ./tmux-scripts.nix { inherit pkgs; };
  inherit (pkgs.tmuxPlugins) dotbar;
  prefix = "$HOME/.local/portable";
  tools = [
    "bat"
    "eza"
    "fd"
    "fzf"
    "ripgrep"
    "starship"
    "zoxide"
  ];
  static = pkgs.pkgsStatic // {
    ripgrep =
      if lib.any (p: (p.pname or "") == "rust-jemalloc-sys") pkgs.pkgsStatic.ripgrep.buildInputs then
        lib.warn "pkgsStatic.ripgrep links jemalloc upstream: remove ripgrep override in nix/portable-shell.nix" pkgs.pkgsStatic.ripgrep
      else
        pkgs.pkgsStatic.ripgrep.overrideAttrs (old: {
          buildInputs = old.buildInputs ++ [ pkgs.pkgsStatic.rust-jemalloc-sys ];
        });
  };
  flylineVersion = "1.10.0";
  flylineRelease = pkgs.fetchurl {
    url = "https://github.com/HalFrgrd/flyline/releases/download/v${flylineVersion}/libflyline-v${flylineVersion}-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-/2ZsPI2YLjoLsI0aUVoZ2kcZr0chZJIgyb49AI8mC+s=";
  };
  flyline =
    if pkgs.flyline.version == flylineVersion then
      flylineRelease
    else
      lib.warn "flyline is ${pkgs.flyline.version} locally but ${flylineVersion} in the portable shell: bump flylineVersion and hash in nix/portable-shell.nix" flylineRelease;
  rewrite =
    builtins.replaceStrings
      (
        [
          "${scripts.hostColor}/bin"
          "${scripts.windowLabel}/bin"
          "${scripts.netStatus}/bin"
          "${dotbar}/share/tmux-plugins"
        ]
        ++ map (t: "${pkgs.${t}}/bin/") tools
      )
      (
        [
          "${prefix}/bin"
          "${prefix}/bin"
          "${prefix}/bin"
          "${prefix}/plugins"
        ]
        ++ map (_: "") tools
      );
  exports =
    attrs: lib.concatStrings (lib.mapAttrsToList (n: v: "export ${n}=${lib.escapeShellArg v}\n") attrs);
  aliases = lib.concatStrings (
    lib.mapAttrsToList (n: v: "alias -- ${n}=${lib.escapeShellArg v}\n") (
      lib.getAttrs [
        "cat"
        "eza"
        "la"
        "ll"
        "lla"
        "ls"
        "lt"
      ] config.programs.bash.shellAliases
    )
  );
  bashrc = ''
    export PATH="${prefix}/bin:$PATH"
    export TERMINFO_DIRS="${prefix}/share/terminfo:''${TERMINFO_DIRS:-/usr/share/terminfo}"
    export STARSHIP_CONFIG="${prefix}/starship.toml"
    export BAT_CONFIG_PATH="${prefix}/bat.conf"
    ${exports (lib.filterAttrs (n: _: lib.hasPrefix "FZF_" n) config.home.sessionVariables)}
    [[ $- == *i* && $TERM != dumb ]] || return 0

    ${aliases}
    eval "$(fzf --bash)"
    eval "$(zoxide init bash ${lib.concatStringsSep " " config.programs.zoxide.options})"
    eval "$(starship init bash --print-full-init)"
    eval "$(up --init bash)"

    enable -f "${prefix}/lib/libflyline.so" flyline
    ${builtins.readFile ../dotfiles/bash/flyline.bash}
  '';
in
pkgs.runCommand "portable-shell"
  {
    conf = rewrite config.xdg.configFile."tmux/tmux.conf".text;
    bashrc = rewrite bashrc;
    passAsFile = [
      "conf"
      "bashrc"
    ];
  }
  ''
    mkdir -p $out/bin $out/lib $out/plugins $out/share
    cp $confPath $out/tmux.conf
    cp $bashrcPath $out/bashrc
    cp ${config.home.file.${config.programs.starship.configPath}.source} $out/starship.toml
    cp ${config.xdg.configFile."bat/config".source} $out/bat.conf

    cp ${static.tmux}/bin/tmux $out/bin/tmux
    for exe in ${lib.concatMapStringsSep " " (t: lib.getExe static.${t}) tools}; do
      wrapped=$(dirname $exe)/.$(basename $exe)-wrapped
      cp $(test -e $wrapped && echo $wrapped || echo $exe) $out/bin/$(basename $exe)
    done
    cp ${../scripts/tmux/host-color.sh} $out/bin/tmux-host-color
    cp ${../scripts/tmux/window-label.sh} $out/bin/tmux-window-label
    cp ${../scripts/tmux/net-status.sh} $out/bin/tmux-net-status
    cp ${../bin/up} $out/bin/up
    cp ${../bin/rg-fuzzy} $out/bin/rg-fuzzy
    tar -xzf ${flyline} -C $out/lib
    mv $out/lib/libflyline.so.* $out/lib/libflyline.so
    cp -r ${dotbar}/share/tmux-plugins/dotbar $out/plugins/dotbar
    cp -r --no-preserve=mode ${pkgs.ncurses}/share/terminfo $out/share/terminfo
    cp -r --no-preserve=mode ${pkgs.kitty.terminfo}/share/terminfo/. $out/share/terminfo/

    for entry in t/tmux-256color x/xterm-kitty; do
      test -e $out/share/terminfo/$entry || { echo "missing terminfo $entry" >&2; exit 1; }
    done
    grep -oh '[$]HOME/[.]local/portable/[[:alnum:]/._-]*' $out/tmux.conf $out/bashrc | while read -r ref; do
      test -e "$out/''${ref#*/.local/portable/}" || { echo "missing $ref" >&2; exit 1; }
    done
    for f in $out/bin/*; do
      if [ "$(head -c2 "$f")" = '#!' ]; then
        if grep -n /nix/store "$f"; then
          echo "$f references the Nix store" >&2
          exit 1
        fi
      elif ${pkgs.binutils-unwrapped}/bin/readelf -l "$f" 2>/dev/null | grep -q 'program interpreter'; then
        echo "$f is dynamically linked" >&2
        exit 1
      fi
    done
    if grep -rn /nix/store $out/tmux.conf $out/bashrc $out/starship.toml $out/bat.conf $out/plugins; then
      echo "bundle still references the Nix store" >&2
      exit 1
    fi
  ''
