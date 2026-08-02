{ inputs, moduleWithSystem, ... }:
{
  perSystem =
    { system, ... }:
    {
      packages.hunk = inputs.hunk.packages.${system}.default;
    };

  flake.modules.homeManager.hunk = moduleWithSystem (
    { config, ... }:
    { ... }:
    {
      home.packages = [ config.packages.hunk ];
    }
  );
}
