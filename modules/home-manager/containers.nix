{ config, ... }:
let
  flake = config.flake;
in
{
  flake.userPackageGroups.containers = pkgs: [
    pkgs.docker_29
    pkgs.docker-compose
  ];

  flake.modules.homeManager.containers =
    { pkgs, ... }:
    {
      home.packages = flake.userPackageGroups.containers pkgs;
    };
}
