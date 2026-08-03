{ config, ... }:
let
  flake = config.flake;
in
{
  flake.userPackageGroups.security =
    pkgs:
    pkgs.lib.optionals pkgs.stdenv.isLinux [
      pkgs.bitwarden-desktop
    ];

  flake.modules.homeManager.security =
    { pkgs, ... }:
    {
      home.packages = flake.userPackageGroups.security pkgs;
    };
}
