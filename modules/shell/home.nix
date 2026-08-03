{ ... }:
{
  flake.modules.hjem."feature/shell/terminal" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (lib.elem "terminal" config.nixComputers.profileFeatures) {
      packages = with pkgs; [
        eza
        ripgrep
        fd
        jq
        nil
      ];
    };

  flake.modules.homeManager."feature/shell/terminal" = { pkgs, ... }: {
    home.packages = with pkgs; [
      eza
      ripgrep
      fd
      jq
      nil
    ];
  };
}
