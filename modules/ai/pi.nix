{
  inputs,
  self,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;

      mkPi =
        module:
        (inputs.agents.packages.${system}.pi.configuration.apply {
          imports = [
            {
              config.models.providers.azure-openai-responses = {
                baseUrl = "https://openai-fornybar-swe.services.ai.azure.com/openai/v1";
                apiKey = "AZURE_API_KEY";
              };
            }
            module
          ];
        }).wrapper;

      baseSettingsModule = {
        config.settings = {
          defaultProvider = "azure-openai-responses";
          defaultModel = "gpt-5.5";
          defaultThinkingLevel = "low";
          mcp.enabled = [ "linear" ];
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
      };

      extensions = [
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
      ];

      skills = [
        "${inputs.agents}/.agents/skills"
        "${self}/.agents/skills"
      ];

    in
    {
      packages.pi = mkPi {
        imports = [ baseSettingsModule ];
        config = {
          binName = "pi";
          settings = {
            inherit skills;
            packages = extensions ++ [ "git:github.com/monochromatti/pi-extensions" ];
          };
        };
      };

      packages.pi-dev = mkPi {
        imports = [ baseSettingsModule ];
        config = {
          binName = "pi-dev";
          filesToExclude = [ "bin/pi" ];
          settings = {
            inherit skills extensions;
          };
        };
      };
    };
}
