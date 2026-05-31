{ config, inputs, ... }:
let
  flake = config.flake;
in
{
  flake.nixosConfigurations = flake.lib.mkNixos "x86_64-linux" "vindos";

  flake.modules.nixos.vindos = {
    imports = [
      inputs.nixos-wsl.nixosModules.default
      flake.modules.nixos.base
      flake.modules.nixos.shell
      flake.modules.nixos."monochromatti-wsl"
    ];

    wsl = {
      enable = true;
      defaultUser = "monochromatti";
    };

    networking.hostName = "vindos";

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    users.users.monochromatti = {
      isNormalUser = true;
      description = "Mattias Matthiesen";
      extraGroups = [ "wheel" ];
    };

    system.stateVersion = "25.11";
  };
}
