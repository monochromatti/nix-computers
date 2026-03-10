{ ... }:
{
  perSystem =
    {
      pkgs,
      inputs',
      ...
    }:
    {
      packages = {
        daily-hours = pkgs.callPackage ../packages/daily-hours { };
        pi = pkgs.callPackage ../packages/pi {
          llmAgentsPi = inputs'.llm-agents.packages.pi;
          aienv = inputs'.agents.packages.aienv;
        };
      };
    };
}
