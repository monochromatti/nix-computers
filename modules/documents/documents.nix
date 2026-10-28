{ ... }:
{
  flake.modules.hjem."feature/documents" =
    {
      pkgs,
      ...
    }:
    {
      packages = with pkgs; [
        glow
        pandoc
        typst
      ];
    };

  flake.modules.homeManager."feature/documents" = { pkgs, ... }: {
    home.packages = with pkgs; [
      glow
      pandoc
      typst
    ];
  };
}
