{
  inputs,
  lib,
  moduleWithSystem,
  ...
}:
{
  perSystem =
    { system, ... }:
    {
      packages.hunk = inputs.hunk.packages.${system}.default;
    };

  flake.modules.hjem."feature/development/hunk" =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (lib.elem "development/hunk" config.nixComputers.profileFeatures) {
      packages = [ inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    };

  flake.modules.homeManager."feature/development/hunk" = moduleWithSystem (
    { config, ... }:
    { ... }:
    {
      home.packages = lib.mkBefore [ config.packages.hunk ];
    }
  );
}
