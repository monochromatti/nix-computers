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
      };
    };
}
