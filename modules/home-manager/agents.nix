{ inputs, ... }:
{
  flake.modules.homeManager.agents =
    { pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      agentPackages = inputs.agents.packages.${system};
    in
    {
      home.packages = [
        agentPackages.codex
        agentPackages.opencode
        agentPackages.claude
        (agentPackages.pi.configuration.apply {
          settings = {
            defaultProvider = "azure-openai-responses";
            defaultModel = "gpt-5.4-mini";
            defaultThinkingLevel = "medium";
            subagents.agentOverrides = {
              "context-builder".model = "azure-openai-responses/gpt-5.4";
              planner.model = "azure-openai-responses/gpt-5.4";
              researcher.model = "azure-openai-responses/gpt-5.4";
              reviewer.model = "azure-openai-responses/gpt-5.3-codex";
              scout.model = "azure-openai-responses/gpt-5.4-mini";
              worker.model = "azure-openai-responses/gpt-5.4";
            };
            packages = [
              "npm:pi-subagents"
              "npm:pi-intercom"
              "npm:pi-web-access"
              "npm:pi-boomerang"
              "npm:pi-skill-palette"
              "npm:pi-mcp-adapter"
              "npm:pi-move-session"
              "npm:pi-prompt-template-model"
              "npm:pi-ghostty"
              "npm:pi-thinking-steps"
              "npm:pi-caveman"
              "git:github.com/monochromatti/pi-extensions"
            ];
          };
        }).wrapper
      ];
    };
}
