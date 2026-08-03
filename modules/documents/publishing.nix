{ ... }:
{
  flake.modules.hjem."feature/documents/publishing" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      latex = pkgs.texliveMedium.withPackages (ps: with ps; [ arara ]);
    in
    lib.mkIf (lib.elem "publishing" config.nixComputers.profileFeatures) {
      packages = [
        pkgs.quarto
        latex
      ];
    };

  flake.modules.homeManager."feature/documents/publishing" =
    { pkgs, ... }:
    let
      latex = pkgs.texliveMedium.withPackages (ps: with ps; [ arara ]);
    in
    {
      home.packages = [
        pkgs.quarto
        latex
      ];
    };
}
