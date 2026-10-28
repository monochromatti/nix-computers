{ ... }:
{
  flake.modules.hjem."feature/shell/terminal" =
    {
      pkgs,
      ...
    }:
    {
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
