{ self, ... }:
{
  perSystem =
    { system, ... }:
    let
      packageSets = self.lib.mkPackageSets system;
    in
    {
      _module.args.pkgs = packageSets.pkgs;
      _module.args.upkgs = packageSets.upkgs;
      _module.args.mpkgs = packageSets.mpkgs;
    };
}
