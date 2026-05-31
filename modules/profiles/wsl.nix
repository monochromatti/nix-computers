{ config, ... }:
let
  flake = config.flake;
in
{
  flake.modules.homeManager.wsl = {
    imports = with flake.modules.homeManager; [
      development
      terminal
      documents
    ];
  };
}
