{ moduleWithSystem, ... }:
{
  perSystem =
    { upkgs, ... }:
    {
      packages.zapp = upkgs.callPackage ../../packages/hardware/zapp/package.nix { };
    };

  flake.modules.darwin."feature/hardware/zapp" = moduleWithSystem (
    { config, ... }:
    { ... }:
    {
      environment.systemPackages = [ config.packages.zapp ];
    }
  );

  flake.modules.nixos."feature/hardware/zapp" = moduleWithSystem (
    { config, ... }:
    { ... }:
    {
      environment.systemPackages = [ config.packages.zapp ];
      services.udev.packages = [ config.packages.zapp ];
    }
  );
}
