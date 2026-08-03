{ config, ... }:
let
  flake = config.flake;
in
{
  flake.userPackageGroups.documents =
    pkgs: with pkgs; [
      glow
      pandoc
      typst
    ];

  flake.modules.homeManager.documents =
    { pkgs, ... }:
    {
      home.packages = flake.userPackageGroups.documents pkgs;
    };
}
