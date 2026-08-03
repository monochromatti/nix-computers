{ config, ... }:
let
  flake = config.flake;
in
{
  flake.modules.nixos."feature/applications/obsidian" = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      obsidian
    ];

  };
}
