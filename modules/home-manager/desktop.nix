{ config, ... }:
let
  flake = config.flake;
in
{
  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    let
      niri-stack = flake.packages.${pkgs.stdenv.hostPlatform.system}.niri-stack;
    in
    {
      home.packages = [ niri-stack ];
    };
}
