{ inputs, ... }:
{
  flake.modules.nixos.shell = {
    imports = with inputs.self.modules.nixos; [
      shellPackages
      shellAliases
      direnv
      starship
      zsh
    ];
  };

  flake.modules.darwin.shell = {
    imports = with inputs.self.modules.darwin; [
      shellPackages
      shellAliases
      direnv
      starship
      zsh
    ];
  };
}
