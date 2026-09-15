{ moduleWithSystem, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.cli-microsoft365 =
        pkgs.callPackage ../../packages/development/cli-microsoft365/package.nix
          { };
    };

  flake.modules.nixos."feature/development/cli-microsoft365" = moduleWithSystem (
    { config, ... }:
    { ... }:
    {
      environment.systemPackages = [ config.packages.cli-microsoft365 ];
    }
  );
}
