{ config, inputs, ... }:
let
  flake = config.flake;
in
{
  perSystem =
    { system, ... }:
    {
      packages.hunk = inputs.hunk.packages.${system}.default;
    };

  flake.modules.homeManager.hunk =
    { pkgs, ... }:
    {
      home.packages = [ flake.packages.${pkgs.stdenv.hostPlatform.system}.hunk ];
    };
}
