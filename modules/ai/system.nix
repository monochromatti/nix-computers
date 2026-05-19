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
      packages."delta-duck-query" = pkgs.callPackage ../../packages/delta-duck-query/package.nix { };

      packages.ai = pkgs.buildEnv {
        name = "ai";
        paths = [
          config.packages.pi
          config.packages.pi-dev
          config.packages."delta-duck-query"
          pkgs.playwright-test
        ];
      };
    };

  flake.modules.darwin.ai = aiModule;
  flake.modules.nixos.ai = aiModule;
}
