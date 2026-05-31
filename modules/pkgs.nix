{ config, ... }:
let
  flake = config.flake;
in
{
  perSystem =
    { system, ... }:
    let
      packageSets = flake.lib.mkPackageSets system;
    in
    {
      _module.args.pkgs = packageSets.pkgs;
      _module.args.upkgs = packageSets.upkgs;
      _module.args.mpkgs = packageSets.mpkgs;
    };
}
