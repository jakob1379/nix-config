{
  config,
  pkgs,
  inputs,
  system,
  ...
}:

{
  config = {
    programs = {
      firefox = {
        enable = true;
        package = inputs."zen-browser".packages.${system}.zen-browser;
        configPath = ".mozilla/firefox";
        profiles.myuser = {
          isDefault = true;
          id = 0;
          settings = {
            "gfx.webrender.all" = true;
            "webgl.force-enabled" = true;
            "webgl.msaa-force" = true;
            "browser.backspace_action" = 0;
            "browser.download.alwaysOpenPanel" = false;
            "services.sync.prefs.sync.browser.uiCustomization.state" = true;
            "browser.sessionstore.restore_pinned_tabs_on_demand" = true;
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          };
          userChrome = builtins.readFile ../../dotfiles/firefox/firefox_userchrome.css;
        };
      };

      ghostty = {
        enable = true;
        settings = {
          background-opacity = 0.85;
          bold-is-bright = true;
          clipboard-paste-protection = false;
          confirm-close-surface = true;
          copy-on-select = "clipboard";
          cursor-style = "block";
          cursor-style-blink = false;
          shell-integration-features = "no-cursor";
          term = "kitty";
          unfocused-split-opacity = 1.0;
          window-decoration = false;
          keybind = [
            "ctrl+shift+,=unbind"
            "ctrl+alt+shift+,=reload_config"
          ];
          # scrollbar = "system";
        };
      };

      vicinae = {
        inherit (config.customPackages.gui) enable;
        package = pkgs.vicinae;
      };

      wallust = {
        enable = true;
      };
    };

    qt.enable = true;

    xdg = {
      mimeApps = {
        enable = true;
        defaultApplications = {
          "application/x-directory" = [ "org.kde.dolphin.desktop" ];
          "application/xhtml+xml" = [ "zen.desktop" ];
          "inode/directory" = [ "org.kde.dolphin.desktop" ];
          "text/html" = [ "zen.desktop" ];
          "x-scheme-handler/file" = [ "org.kde.dolphin.desktop" ];
          "x-scheme-handler/http" = [ "zen.desktop" ];
          "x-scheme-handler/https" = [ "zen.desktop" ];
        };
      };
      terminal-exec = {
        enable = true;
        settings.default = [ "com.mitchellh.ghostty.desktop" ];
      };
      autostart = {
        enable = true;
        entries = [ "${pkgs.netbird-ui}/share/applications/netbird.desktop" ];
      };
    };
  };
}
