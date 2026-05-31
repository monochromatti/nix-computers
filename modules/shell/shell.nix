{ config, ... }:
let
  flake = config.flake;
in
{
  flake.modules.nixos.shell = {
    imports = with flake.modules.nixos; [
      shellPackages
      shellAliases
      direnv
      starship
      zsh
    ];
  };

  flake.modules.darwin.shell = {
    imports = with flake.modules.darwin; [
      shellPackages
      shellAliases
      direnv
      starship
      zsh
    ];
  };
}
