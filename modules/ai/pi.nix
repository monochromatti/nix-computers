{ inputs, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      agentPackages = inputs.agents.packages.${system};
      mkPi =
        moduleConfig:
        (agentPackages.pi.configuration.apply (
          { ... }:
          {
            config = {
              models.providers.azure-openai-responses = {
                baseUrl = "https://openai-fornybar-swe.services.ai.azure.com/openai/v1";
                apiKey = "AZURE_API_KEY";
              };
            }
            // moduleConfig;
          }
        )).wrapper;
      baseSettings = {
        defaultProvider = "azure-openai-responses";
        defaultModel = "gpt-5.5";
        defaultThinkingLevel = "low";
        subagents.agentOverrides = {
          "context-builder".model = "azure-openai-responses/gpt-5.5";
          oracle.model = "azure-openai-responses/gpt-5.5";
          "oracle-executor".model = "azure-openai-responses/gpt-5.5";
          planner.model = "azure-openai-responses/gpt-5.5";
          researcher.model = "azure-openai-responses/gpt-5.5";
          reviewer.model = "azure-openai-responses/gpt-5.5";
          scout.model = "azure-openai-responses/gpt-5.4-mini";
          worker.model = "azure-openai-responses/gpt-5.5";
        };
      };
    in
    {
      packages.pi = mkPi {
        binName = "pi";
        settings = baseSettings // {
          packages = [
            "npm:pi-subagents"
            "npm:pi-intercom"
            "npm:pi-web-access"
            "npm:pi-boomerang"
            "npm:pi-skill-palette"
            "npm:pi-move-session"
            "npm:pi-prompt-template-model"
            "npm:pi-ghostty"
            "npm:pi-thinking-steps"
            "npm:pi-caveman"
            "npm:pi-mcp-adapter"
            "git:github.com/monochromatti/pi-extensions"
          ];
          skills = [
            "${inputs.agents}/.agents/skills"
            "${self}/.agents/skills"
          ];
        };
      };

      packages.pi-dev =
        (mkPi {
          binName = "pi-dev";
          filesToExclude = [ "bin/pi" ];
          settings = baseSettings // {
            packages = [ ];
            skills = [ ];
          };
        }).overrideAttrs
          (old: {
            meta = (old.meta or { }) // {
              mainProgram = "pi-dev";
            };
          });
    };
}
