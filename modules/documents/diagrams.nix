{ ... }:
{
  flake.modules.hjem."feature/documents/diagrams" =
    {
      pkgs,
      ...
    }:
    {
      packages = with pkgs; [
        d2
        silicon
      ];
    };

  flake.modules.homeManager."feature/documents/diagrams" = { pkgs, ... }: {
    home.packages = with pkgs; [
      d2
      silicon
    ];
  };
}
