{ config, ... }:
let
  flake = config.flake;
in
{
  flake.modules.nixos.packages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      obsidian
    ];

  };
}
