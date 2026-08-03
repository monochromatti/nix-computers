{ config, ... }:
let
  flake = config.flake;
in
{
  flake.userPackageGroups.publishing =
    pkgs:
    let
      latex = pkgs.texliveMedium.withPackages (ps: with ps; [ arara ]);
    in
    [
      pkgs.quarto
      latex
    ];

  flake.modules.homeManager.publishing =
    { pkgs, ... }:
    {
      home.packages = flake.userPackageGroups.publishing pkgs;
    };
}
