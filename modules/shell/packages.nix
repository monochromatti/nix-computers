{ ... }:
let
  packagesModule =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        tree
        lazygit
        yazi
        starship
        zoxide
        fzf
      ];
    };
in
{
  flake.modules.darwin.shellPackages = packagesModule;
  flake.modules.nixos.shellPackages = packagesModule;
}
