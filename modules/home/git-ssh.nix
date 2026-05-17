{
  config,
  pkgs,
  lib,
  ...
}:

let
  sshSocketDir = config.home.homeDirectory + "/.ssh/sockets";
in
{
  options = {
    customGit = {
      userName = lib.mkOption {
        type = lib.types.str;
        default = "Your Name";
        description = "Default Git user name.";
      };
      userEmail = lib.mkOption {
        type = lib.types.str;
        default = "your.email@example.com";
        description = "Default Git user email.";
      };
    };

    customSsh = {
      enableKeepassxc = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable KeepassXC integration for SSH connections.";
      };
    };
  };

  config = {
    home = {
      activation.ensureSshSocketsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.coreutils}/bin/mkdir -p "${sshSocketDir}"
        ${pkgs.coreutils}/bin/chmod 700 "${config.home.homeDirectory}/.ssh"
        ${pkgs.coreutils}/bin/chmod 700 "${sshSocketDir}"
      '';

      file = lib.optionalAttrs config.customSsh.enableKeepassxc {
        ".ssh/keepassxc-prompt".source = ../../scripts/ssh/keepassxc-prompt.sh;
      };
    };

    programs = {
      git = {
        enable = true;
        signing = {
          format = "openpgp";
          key = "98BD7E80842C97BA";
          signByDefault = false;
        };
        settings = lib.mkForce [
          {
            user = {
              name = config.customGit.userName;
              email = config.customGit.userEmail;
            };
            checkout.defaultRemote = "origin";
            color = {
              diff = "auto";
              ui = true;
            };
            init.defaultBranch = "main";
            pull.rebase = false;
            push.autoSetupRemote = true;
            # credential.helper = "libsecret"; # Keep your existing system helper
            alias = {
              adog = "log --all --decorate --oneline --graph";
              plog = "log --all --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --branches";
              ignore-change = "update-index --assume-unchanged";
              unstage = "restore --staged";
            };

            credential = {
              "https://gitlab.com".helper = "!${pkgs.glab}/bin/glab auth git-credential";
              "https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
              "https://gist.github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
            };
          }
        ];
      };

      gh = {
        enable = true;
        extensions = [
          pkgs.gh-dash
          pkgs.gh-poi
          pkgs.gh-stack
        ];
        gitCredentialHelper.enable = true;
        settings.aliases = {
          web = "repo view --web";
        };
      };

      gpg.enable = true;

      keepassxc = {
        enable = true;
        autostart = false;
        package = pkgs.keepassxc;
      };

      ssh = {
        enable = true;
        enableDefaultConfig = false;
        includes = [ "~/.ssh/local_config" ];
        # extraOptionOverrides = lib.optionalAttrs config.customSsh.enableKeepassxc {
        #   ProxyCommand = "$HOME/.ssh/keepassxc-prompt %h %p";
        # };

        extraConfig = ''
          Match exec "${pkgs.netbird}/bin/netbird ssh detect %h %p"
          ControlMaster no
          ControlPath none
          ControlPersist no
        '';
        matchBlocks = {
          "*" = {
            forwardAgent = true;
            addKeysToAgent = "yes";
            controlMaster = "auto";
            controlPath = "~/.ssh/sockets/%r@%h-%p";
            controlPersist = "yes";
            serverAliveInterval = 30;
            serverAliveCountMax = 3;
          };
        };
      };
    };

    xdg = {
      configFile."autostart/org.keepassxc.KeePassXC.desktop".text = ''
        [Desktop Entry]
        Name=KeePassXC
        Exec=keepassxc
        TryExec=keepassxc
        Icon=keepassxc
        StartupNotify=false
        Terminal=false
        Type=Application
        Version=1.5
        X-GNOME-Autostart-enabled=true
      '';

      dataFile."applications/org.keepassxc.KeePassXC.desktop".text = ''
        [Desktop Entry]
        Name=KeePassXC
        GenericName=Password Manager
        Comment=Community-driven port of KeePass Password Safe
        Exec=keepassxc %f
        TryExec=keepassxc
        Icon=keepassxc
        StartupWMClass=keepassxc
        StartupNotify=false
        Terminal=false
        Type=Application
        Version=1.5
        Categories=Utility;Security;Qt;
        MimeType=application/x-keepass2;
        SingleMainWindow=true
        X-GNOME-SingleWindow=true
        Keywords=security;privacy;password-manager;yubikey;password;keepass;
      '';
    };
  };
}
