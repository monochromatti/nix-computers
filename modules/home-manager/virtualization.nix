{ config, ... }:
let
  flake = config.flake;
in
{
  flake.userPackageGroups.virtualization = pkgs: [ pkgs.qemu ];

  flake.modules.homeManager.virtualization =
    { pkgs, ... }:
    {
      home.packages = flake.userPackageGroups.virtualization pkgs;
    };
}
