{ inputs, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      agentPackages = inputs.agents.packages.${system};
    in
    {
      packages.pi =
        (agentPackages.pi.configuration.apply (
          { ... }:
          let
            settings = {
              defaultProvider = "azure-openai-responses";
              defaultModel = "azure-openai-responses/gpt-5.5:low";
              defaultThinkingLevel = "medium";
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
          in
          {
            config = {
              inherit settings;
            };
          }
        )).wrapper;
    };
}
