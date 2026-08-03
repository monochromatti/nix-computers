{ config, ... }:
let
  flake = config.flake;
in
{
  flake.userPackageGroups.cloud = pkgs: [ pkgs.azure-cli ];

  flake.modules.homeManager.cloud =
    { pkgs, ... }:
    {
      home.packages = flake.userPackageGroups.cloud pkgs;
    };
}
