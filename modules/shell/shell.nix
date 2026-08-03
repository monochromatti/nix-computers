{ config, ... }:
let
  flake = config.flake;
in
{
  flake.modules.nixos."profile/shell" = {
    imports = [
      flake.modules.nixos."feature/shell/packages"
      flake.modules.nixos."feature/shell/aliases"
      flake.modules.nixos."feature/shell/direnv"
      flake.modules.nixos."feature/shell/starship"
      flake.modules.nixos."feature/shell/zsh"
    ];
  };

  flake.modules.darwin."profile/shell" = {
    imports = [
      flake.modules.darwin."feature/shell/packages"
      flake.modules.darwin."feature/shell/aliases"
      flake.modules.darwin."feature/shell/direnv"
      flake.modules.darwin."feature/shell/starship"
      flake.modules.darwin."feature/shell/zsh"
    ];
  };
}
