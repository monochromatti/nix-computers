{ inputs, ... }:
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "homunculus";

  flake.modules.nixos.homunculus =
    { pkgs, ... }:
    {
      imports = [
        inputs.self.modules.nixos.lima
        inputs.self.modules.nixos.shell
      ];

      networking.hostName = "homunculus";

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
