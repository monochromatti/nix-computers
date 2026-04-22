{ inputs, ... }:
{
  perSystem =
    { pkgs, config, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      agentPackages = inputs.agents.packages.${system};
    in
    {
      packages.ai = pkgs.buildEnv {
        name = "ai";
        paths = [
          agentPackages.codex
          agentPackages.opencode
          agentPackages.claude
          config.packages.pi
        ];
      };
    };
}
