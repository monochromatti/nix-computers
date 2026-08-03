{ config, ... }:
let
  flake = config.flake;
in
{
  flake.userPackageGroups.terminal =
    pkgs: with pkgs; [
      eza
      ripgrep
      fd
      jq
      nil
    ];

  flake.modules.homeManager.terminal =
    { pkgs, ... }:
    {
      home.packages = flake.userPackageGroups.terminal pkgs;
    };
}
