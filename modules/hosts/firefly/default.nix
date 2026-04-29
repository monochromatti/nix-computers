{ inputs, ... }:
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "firefly";

  flake.modules.nixos.firefly = {
    imports = with inputs.self.modules.nixos; [
      base
      shell
      secrets
      packages
      niri

      inputs.pc.nixosModules.hdw-hp-zbook-firefly_g11
      inputs.pc.nixosModules.default
      inputs.pc.nixosModules.docker
      inputs.utgard.nixosModules.aruba-onboard

      monochromatti
    ];

    midgard.pc = {
      desktop = null;
      hostName = "firefly";
      users = {
        monochromatti = {
          fullName = "Mattias Matthiesen";
          email = "mattias.matthiesen@eviny.no";
          git.userName = "monochromatti";
          home-manager.enable = true;
        };
      };
      nixbuild.enable = true;
    };

    virtualisation.docker.enable = true;

    system.stateVersion = "24.05";
  };
}
