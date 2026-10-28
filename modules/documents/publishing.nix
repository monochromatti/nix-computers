{ ... }:
{
  flake.modules.hjem."feature/documents/publishing" =
    {
      pkgs,
      ...
    }:
    let
      latex = pkgs.texliveMedium.withPackages (ps: with ps; [ arara ]);
    in
    {
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
