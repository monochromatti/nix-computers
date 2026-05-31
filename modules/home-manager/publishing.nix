{
  flake.modules.homeManager.publishing =
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
