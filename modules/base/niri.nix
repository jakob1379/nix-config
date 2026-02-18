{
  inputs,
  ...
}:

{
  imports = [ inputs.noctalia.homeManagerModules.noctalia ];

  programs.niri = {
    enable = true;
    settings = {
      spawn-at-startup = [
        { command = [ "noctalia-shell" ]; }
      ];

      binds."Mod+Space".action.spawn = [
        "noctalia-shell"
        "ipc"
        "call"
        "launcher"
        "toggle"
      ];
    };
  };
}
