{ config, ... }:
let
  flake = config.flake;
in
{
  flake.nixosConfigurations = flake.lib.mkNixos "aarch64-linux" "linux";

  flake.modules.nixos.linux =
    { pkgs, ... }:
    {
      imports = [
        flake.modules.nixos.lima
        flake.modules.nixos.shell
      ];

      networking.hostName = "linux";

      security.sudo.wheelNeedsPassword = false;

      environment.systemPackages = with pkgs; [
        azure-cli
        gh
        git
        ripgrep
      ];

      system.stateVersion = "25.11";
    };
}
