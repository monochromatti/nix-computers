{ inputs, ... }:
let
  aiModule =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.ai
      ];
    };
in
{
  perSystem =
    { pkgs, config, ... }:
    {
      packages.ai = pkgs.buildEnv {
        name = "ai";
        paths = [
          config.packages.pi
          config.packages.pi-dev
          pkgs.playwright-test
        ];
      };
    };

  flake.modules.darwin.ai = aiModule;
  flake.modules.nixos.ai = aiModule;
}
