{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  homelabRepo = "/opt/homelab";
  homelabBranch = "main";
  homelabPodsCompose = "docker-compose.pods.yml";

  dockhandBootstrapUpdate = pkgs.writeShellApplication {
    name = "dockhand-bootstrap-update";
    runtimeInputs = with pkgs; [
      coreutils
      docker
      docker-compose
      git
      gnugrep
      util-linux
    ];
    text = ''
      set -Eeuo pipefail

      repo_dir="''${HOMELAB_REPO:-/opt/homelab}"
      branch="''${HOMELAB_BRANCH:-main}"
      lock_file="''${HOMELAB_LOCK_FILE:-/run/lock/homelab-dockhand-bootstrap-update.lock}"
      compose_file="''${HOMELAB_PODS_COMPOSE:-docker-compose.pods.yml}"

      log() {
        printf '%s\n' "$*"
      }

      if ! git check-ref-format "refs/heads/$branch"; then
        log "Invalid branch name: $branch"
        exit 2
      fi

      exec 9>"$lock_file"
      if ! flock -n 9; then
        log "Another Dockhand bootstrap update is already running"
        exit 0
      fi

      cd "$repo_dir"

      current_branch="$(git branch --show-current)"
      if [ "$current_branch" != "$branch" ]; then
        log "Refusing to update: checkout is on '$current_branch', expected '$branch'"
        exit 1
      fi

      dirty_status="$(git status --porcelain)"
      if [ -n "$dirty_status" ]; then
        log "Refusing to update dirty checkout:"
        printf '%s\n' "$dirty_status"
        exit 1
      fi

      before="$(git rev-parse HEAD)"

      git fetch --prune origin "+refs/heads/$branch:refs/remotes/origin/$branch"

      remote="$(git rev-parse "refs/remotes/origin/$branch")"
      if [ "$before" = "$remote" ]; then
        log "Already current at $before"
        exit 0
      fi

      git merge --ff-only "origin/$branch"

      after="$(git rev-parse HEAD)"
      changed_paths="$(git diff --name-only "$before" "$after" --)"

      log "Updated $branch from $before to $after"

      watch_only_paths="$(
        printf '%s\n' "$changed_paths" \
          | grep -Fx -e ".env.example" -e "setup-dev.sh" -e "docs/dockhand.md" || true
      )"
      if [ -n "$watch_only_paths" ]; then
        log "Watch-only paths changed:"
        printf '%s\n' "$watch_only_paths"
      fi

      redeploy_paths="$(
        printf '%s\n' "$changed_paths" \
          | grep -Fx -e "$compose_file" -e "services/pods.yml" || true
      )"
      if [ -z "$redeploy_paths" ]; then
        log "No Dockhand bootstrap compose changes detected; skipping redeploy"
        exit 0
      fi

      log "Dockhand bootstrap compose paths changed:"
      printf '%s\n' "$redeploy_paths"

      docker compose -f "$compose_file" config >/dev/null
      docker compose -f "$compose_file" pull
      docker compose -f "$compose_file" up -d --remove-orphans
      docker compose -f "$compose_file" ps
    '';
  };
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  networking.hostName = "homelab";
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "docker0" ]; # default Docker bridge
    allowedTCPPorts = [ 8123 ]; # HA port (host-facing)
  };

  time.timeZone = "Europe/Copenhagen";

  services.qemuGuest.enable = true;
  services.resolved.enable = true;
  services.netbird.enable = true;

  systemd.services.${config.services.netbird.clients.default.service.name}.path = [
    pkgs.shadow
    pkgs.util-linux
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "nodev" ];
  boot.growPartition = true;
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.arp_ignore" = 1;
    "net.ipv4.conf.all.arp_announce" = 2;
  };

  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "jsg"
        "deploy"
      ];
      auto-optimise-store = true;
    };
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    nano
    curl
    bat
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  users.users.jsg = {
    isNormalUser = true;
    description = "Jakob Stender Guldberg";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    initialHashedPassword = "$y$j9T$VJd3I/BqxcnLrCv0HnRx1.$IhfmwBjIiqWz0seqIJ19ujfowZRV6718lzsFZ4cdrp5";
  };

  systemd.services.expire-initial-jsg-password = {
    description = "Expire the initial jsg password on first boot";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-user-sessions.service" ];
    unitConfig.ConditionFirstBoot = true;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.shadow}/bin/cha" + "ge -d 0 jsg";
    };
  };

  systemd.services.dockhand-bootstrap-update = {
    description = "Update homelab Dockhand bootstrap stack";
    wants = [ "network-online.target" ];
    requires = [ "docker.service" ];
    after = [
      "network-online.target"
      "docker.service"
    ];

    environment = {
      HOMELAB_REPO = homelabRepo;
      HOMELAB_BRANCH = homelabBranch;
      HOMELAB_PODS_COMPOSE = homelabPodsCompose;
    };

    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "10min";
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "dockhand-bootstrap-update";
      ExecStart = lib.getExe dockhandBootstrapUpdate;
    };
  };

  systemd.timers.dockhand-bootstrap-update = {
    description = "Periodically update homelab Dockhand bootstrap stack";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "30min";
      RandomizedDelaySec = "5min";
      Persistent = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d /opt/homelab 0755 root root -"
  ];

  virtualisation.docker.enable = true;

  security.sudo.package = pkgs.sudo.override { withInsults = true; };

  system.stateVersion = "25.05";
}
