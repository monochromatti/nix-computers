{ ... }:
{
  flake.modules.hjem."feature/documents/diagrams" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (lib.elem "diagrams" config.nixComputers.profileFeatures) {
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
