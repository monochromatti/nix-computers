{ config, ... }:
let
  flake = config.flake;
in
{
  flake.userPackageGroups.desktop = pkgs: [
    flake.packages.${pkgs.stdenv.hostPlatform.system}.niri-stack
  ];

  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      home.packages = flake.userPackageGroups.desktop pkgs;
    };
}
