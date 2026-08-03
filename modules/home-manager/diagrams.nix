{ config, ... }:
let
  flake = config.flake;
in
{
  flake.userPackageGroups.diagrams = pkgs: [
    pkgs.d2
    pkgs.silicon
  ];

  flake.modules.homeManager.diagrams =
    { pkgs, ... }:
    {
      home.packages = flake.userPackageGroups.diagrams pkgs;
    };
}
