{ moduleWithSystem, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.nautilus-copy-path =
        pkgs.callPackage ../../packages/desktop/nautilus-copy-path/package.nix
          { };
    };

  flake.modules.nixos."feature/desktop/nautilus-copy-path" = moduleWithSystem (
    { config, ... }:
    { pkgs, ... }:
    {
      environment.systemPackages = [
        config.packages.nautilus-copy-path
        pkgs.nautilus-python
      ];
    }
  );
}
