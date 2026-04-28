{ ... }:
{
  perSystem =
    { pkgs, config, ... }:
    {
      packages.ai = pkgs.buildEnv {
        name = "ai";
        paths = [
          config.packages.pi
          config.packages.pi-dev
        ];
      };
    };
}
