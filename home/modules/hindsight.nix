{
  config,
  pkgs,
  lib,
  system,
  inputs,
  ...
}:

let
  postgres = pkgs.postgresql_18.withPackages (p: [ p.pgvector ]);
  pgData = "${config.xdg.dataHome}/hindsight/postgres";

  # The default embeddings and reranker providers run in-process and need torch.
  hindsight = inputs.numtide-llm-agents.packages.${system}.hindsight.overridePythonAttrs (old: {
    dependencies = old.dependencies ++ old.optional-dependencies.local-ml;
  });

  codingAgents = pkgs.fetchzip {
    name = "hindsight-coding-agents-0.8.2";
    url = "https://registry.npmjs.org/@vectorize-io/hindsight-coding-agents/-/hindsight-coding-agents-0.8.2.tgz";
    hash = "sha256-9qYHkHBjiTUG5fKXj7+R4pWqNF/RjntE3WK/dQjspEY=";
  };

  node = lib.getExe pkgs.nodejs;

  hook = file: timeout: [
    {
      hooks = [
        {
          type = "command";
          command = "${node} ${codingAgents}/dist/${file}";
          inherit timeout;
        }
      ];
    }
  ];

  hindsightStart = pkgs.writeShellApplication {
    name = "hindsight-start";
    runtimeInputs = [ pkgs.libsecret ];
    text = ''
      HINDSIGHT_API_LLM_API_KEY="$(secret-tool lookup service hindsight key anthropic-api-key)"
      export HINDSIGHT_API_LLM_API_KEY
      exec ${lib.getExe hindsight}
    '';
  };
in
{
  home.file.".hindsight/coding-agent.json".text = builtins.toJSON {
    serverMode = "self-hosted";
    apiUrl = "http://127.0.0.1:8888";
    autoUpdate = false;
  };

  programs.claude-code = {
    skills.hindsight-coding-agent = "${codingAgents}/skill";

    mcpServers.hindsight = {
      type = "stdio";
      command = node;
      args = [ "${codingAgents}/dist/mcp-server.js" ];
      env.HINDSIGHT_MCP_HARNESS = "claude-code";
    };

    settings.hooks = {
      SessionStart = hook "claude-sessionstart-hook.js" 30;
      UserPromptSubmit = hook "claude-hook.js" 30;
      Stop = hook "claude-stop-hook.js" 60;
    };
  };

  systemd.user.services = {
    hindsight-postgres = {
      Unit.Description = "PostgreSQL for Hindsight";
      Service = {
        Type = "notify";
        RuntimeDirectory = "hindsight";
        ExecStartPre = pkgs.writeShellScript "hindsight-postgres-init" ''
          [ -e ${pgData}/PG_VERSION ] || ${postgres}/bin/initdb -D ${pgData} --auth-local=peer --auth-host=reject
        '';
        ExecStart = "${postgres}/bin/postgres -D ${pgData} -k %t/hindsight -c listen_addresses=";
      };
    };

    hindsight = {
      Unit = {
        Description = "Hindsight agent memory server";
        Requires = [ "hindsight-postgres.service" ];
        After = [ "hindsight-postgres.service" ];
      };
      Service = {
        Environment = [
          # An empty host collapses to postgresql:/postgres in hindsight's URL normalizer.
          "HINDSIGHT_API_DATABASE_URL=postgresql://${config.home.username}@/postgres?host=%t/hindsight"
          "HINDSIGHT_API_HOST=127.0.0.1"
          "HINDSIGHT_API_PORT=8888"
          "HINDSIGHT_API_LLM_PROVIDER=anthropic"
        ];
        ExecStart = lib.getExe hindsightStart;
        Restart = "on-failure";
        RestartSec = 30;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
