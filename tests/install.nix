{
  pkgs,
  home,
  installScript,
}:
let
  inherit (home.config.home) username homeDirectory;
in
pkgs.testers.runNixOSTest {
  name = "install";
  nodes.machine = {
    users.users.${username} = {
      isNormalUser = true;
      home = homeDirectory;
    };
    virtualisation = {
      memorySize = 2048;
      diskSize = 4096;
      additionalPaths = [ home.activationPackage ];
    };
  };
  testScript = ''
    import shlex

    def as_user(cmd):
        return machine.succeed("su - ${username} -c " + shlex.quote(cmd))

    machine.wait_for_unit("multi-user.target")

    out = as_user("bash ${installScript}")
    assert "Nix is already installed" in out, out
    as_user("bash ${installScript}")
    machine.succeed("test $(grep -c '^experimental-features = nix-command flakes$' ${homeDirectory}/.config/nix/nix.conf) = 1")

    as_user("${home.activationPackage}/activate")
    as_user("${home.activationPackage}/activate")
    machine.succeed("readlink -f ${homeDirectory}/.config/tmux/tmux.conf | grep -q '^/nix/store/'")
    machine.succeed("test $(stat -c %a ${homeDirectory}/.ssh) = 700")
    as_user("tmux -V")
  '';
}
