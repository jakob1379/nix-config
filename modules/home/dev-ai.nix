{
  config,
  pkgs,
  inputs,
  ...
}:

let
  opencodeMainModel = "openai/gpt-5.5";
  opencodeSmallModel = "openai/gpt-5.5";
  opencodeSlimSettings = {
    "$schema" = "https://unpkg.com/oh-my-opencode-slim@latest/oh-my-opencode-slim.schema.json";
    autoUpdate = true;
    preset = "openai";
    presets = {
      openai = {
        orchestrator = {
          model = opencodeMainModel;
          variant = "high";
          skills = [ "*" ];
          mcps = [
            "*"
            "!context7"
          ];
        };
        oracle = {
          model = opencodeMainModel;
          variant = "high";
          skills = [ "simplify" ];
          mcps = [ ];
        };
        librarian = {
          model = opencodeSmallModel;
          variant = "low";
          skills = [ ];
          mcps = [
            "websearch"
            "context7"
            "grep_app"
          ];
        };
        explorer = {
          model = opencodeSmallModel;
          variant = "low";
          skills = [ ];
          mcps = [ ];
        };
        designer = {
          model = opencodeSmallModel;
          variant = "medium";
          skills = [ "agent-browser" ];
          mcps = [ ];
        };
        fixer = {
          model = opencodeSmallModel;
          variant = "low";
          skills = [ ];
          mcps = [ ];
        };
      };
    };
  };
in
{
  imports = [
    inputs.nix-index-database.homeModules.default
  ];

  config = {
    home.packages = [ pkgs.agent-browser ];

    programs = {
      distrobox = {
        enable = true;
        containers = {
          ubuntu25 = {
            image = "ubuntu:24.04"; # Specify your desired image here
            init_hooks = "curl -LsSf https://astral.sh/uv/install.sh | sh";
            additional_packages = "curl"; # Additional packages needed for init_hooks
            entry = true; # Make this container enterable by default (optional)
          };
        };
      };

      emacs = {
        enable = true;
        package = pkgs.emacs-pgtk;
      };

      difftastic = {
        enable = true;
        git.enable = true;
      };

      nix-init.enable = true;

      opencode = {
        commands = {
          desloppify = builtins.readFile ../../dotfiles/opencode/commands/desloppify.md;
        };

        enable = true;
        settings = {
          lsp = {
            markdown = {
              extensions = [ ".md" ];
              command = [
                "nix"
                "run"
                "nixpkgs#marksman"
                "--"
                "server"
              ];
            };

            nixd = {
              extensions = [ ".nix" ];
              command = [
                "nix"
                "run"
                "nixpkgs#nixd"
                "--"
              ];
            };

            gopls = {
              extensions = [ ".go" ];
              command = [
                "nix"
                "run"
                "nixpkgs#gopls"
                "--"
              ];
            };

            rust = {
              extensions = [ ".rs" ];
              command = [
                "nix"
                "run"
                "nixpkgs#rust-analyzer"
                "--"
              ];
            };

            pyright = {
              disabled = true;
            };

            ruff = {
              command = [
                "uv"
                "run"
                "--with"
                "ruff"
                "ruff"
                "server"
              ];
              extensions = [
                ".py"
                ".pyi"
              ];
            };

            ty = {
              command = [
                "uv"
                "run"
                "--with"
                "ty"
                "ty"
                "server"
              ];
              extensions = [
                ".py"
                ".pyi"
              ];
            };
          };

          mcp = {
            context7 = {
              type = "remote";
              url = "https://mcp.context7.com/mcp";
              enabled = true;
            };
          };

          provider = {
            deepseek = {
              options = {
                apiKey = "{env:DEEPSEEK_API_KEY}";
                baseURL = "https://api.deepseek.com/v1";
              };
            };

            openai = {
              models = {
                "gpt-5.5" = {
                  options = {
                    reasoningEffort = "high";
                  };
                  variants = {
                    low = {
                      reasoningEffort = "low";
                    };
                    high = {
                      reasoningEffort = "high";
                    };
                    xhigh = {
                      reasoningEffort = "xhigh";
                    };
                  };
                };
              };
            };
          };

          model = opencodeMainModel;
          small_model = opencodeSmallModel;

          plugin = [
            "oh-my-opencode-slim@latest"
            "@mohak34/opencode-notifier@latest"
            "@franlol/opencode-md-table-formatter@latest"
            "opencode-devcontainers"
          ];

          agent = {
            explore = {
              disable = true;
            };
            general = {
              disable = true;
            };
          };
        };

        tui = {
          plugin = [ "oh-my-opencode-slim@latest" ];
          keybinds = {
            app_exit = "ctrl+shift+q";
            input_clear = "ctrl+c";
          };
        };
      };

      nix-index-database.comma.enable = true;
      nix-index.enable = true;

      nix-search-tv = {
        enable = true;
        settings = {
          update_interval = "12h";
        };
      };

      uv = {
        enable = true;
        settings = {
          python-preference = "managed";
        };
      };
    };

    xdg.configFile = {
      "opencode/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink (
        config.home.homeDirectory + "/.config/home-manager/dotfiles/AGENTS.md"
      );
      "opencode/oh-my-opencode-slim.json".text = builtins.toJSON opencodeSlimSettings;
      "opencode/skills/agent-browser".source = "${inputs.agent-browser-src}/skills/agent-browser";
      "opencode/skills/codemap".source = "${inputs.oh-my-opencode-slim-src}/src/skills/codemap";
      "opencode/skills/simplify".source = "${inputs.oh-my-opencode-slim-src}/src/skills/simplify";
    };
  };
}
