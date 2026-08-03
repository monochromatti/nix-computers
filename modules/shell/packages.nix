{ ... }:
let
  packagesModule =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        tree
        nix-output-monitor
        lazygit
        jujutsu
        jjui
        yazi
        starship
        zoxide
        fzf
      ];
    };
in
{
  flake.modules.darwin."feature/shell/packages" = packagesModule;
  flake.modules.nixos."feature/shell/packages" = packagesModule;
}
