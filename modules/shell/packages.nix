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
  flake.modules.darwin.shellPackages = packagesModule;
  flake.modules.nixos.shellPackages = packagesModule;
}
