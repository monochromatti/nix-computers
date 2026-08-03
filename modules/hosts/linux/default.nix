{ config, ... }:
let
  flake = config.flake;
in
{
  flake.nixosConfigurations = flake.lib.mkNixos "x86_64-linux" "linux";

  flake.modules.nixos."host/linux" =
    { pkgs, ... }:
    {
      imports = [
        flake.modules.nixos."feature/virtualization/lima"
        flake.modules.nixos."profile/shell"
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
