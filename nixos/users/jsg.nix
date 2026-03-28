{
  pkgs,
  ...
}:

{
  nix.settings.trusted-users = [ "jsg" ];

  users.users.jsg = {
    isNormalUser = true;
    description = "Jakob Stender Guldberg";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "libvirtd"
    ];
    packages = with pkgs; [ libsecret ];
  };

  security.pam = {
    u2f = {
      enable = true;
      settings.cue = true;
    };
    yubico = {
      enable = true;
      control = "sufficient";
      mode = "challenge-response";
      id = [
        "22313001"
        "22313027"
      ];
    };
    services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
    };
  };
}
