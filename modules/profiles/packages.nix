{ config, ... }:
let
  flake = config.flake;
in
{
  flake.modules.homeManager.packages = {
    imports = with flake.modules.homeManager; [
      workstation
      desktop
      security
    ];
  };

  flake.modules.nixos.packages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      obsidian
    ];

    home-manager.sharedModules = [
      flake.modules.homeManager.apps
    ];
  };
}
