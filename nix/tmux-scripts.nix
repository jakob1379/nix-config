{ pkgs }:
{
  netStatus = pkgs.writeShellApplication {
    name = "tmux-net-status";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.iputils
      pkgs.iproute2
      pkgs.tmux
    ];
    text = builtins.readFile ../scripts/tmux/net-status.sh;
  };
  windowLabel = pkgs.writeShellApplication {
    name = "tmux-window-label";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
    ];
    text = builtins.readFile ../scripts/tmux/window-label.sh;
  };
  hostColor = pkgs.writeShellApplication {
    name = "tmux-host-color";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.tmux
    ];
    text = builtins.readFile ../scripts/tmux/host-color.sh;
  };
}
