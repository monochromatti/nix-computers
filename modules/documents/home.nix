{ ... }:
{
  flake.modules.hjem."feature/documents" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (lib.elem "documents" config.nixComputers.profileFeatures) {
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
