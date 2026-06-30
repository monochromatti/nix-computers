{ config, inputs, ... }:
let
  flake = config.flake;
in
{
  flake.nixosConfigurations = flake.lib.mkNixos "x86_64-linux" "firefly";

  flake.modules.nixos.firefly = { pkgs, ... }: {
    imports = with flake.modules.nixos; [
      base
      shell
      secrets
      packages
      hardware
      niri
      flake.modules.nixos.dailyHours

      inputs.linear-notification-daemon.nixosModules.default
      inputs.pc.nixosModules.hdw-hp-zbook-firefly_g11
      inputs.pc.nixosModules.default
      inputs.pc.nixosModules.docker
      inputs.utgard.nixosModules.aruba-onboard

      monochromatti
    ];

    nixpkgs.config.permittedInsecurePackages = [
      "electron-39.8.10"
    ];

    midgard.pc = {
      desktop = null;
      hostName = "firefly";
      security = {
        paretosecurity.enable = false;
        secureboot.enable = false;
      };
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

    environment.systemPackages = with pkgs; [
      proton-vpn
      proton-vpn-cli
    ];

    services.mullvad-vpn.enable = true;

    services.linear-notify = {
      enable = true;
      user = "monochromatti";
      tokenFile = "/run/secrets/linear-api-key";
      intervalSeconds = 45;
      extraArgs = [
        "--page-size"
        "50"
      ];
      enableActions = false;
    };

    virtualisation.docker = {
      enable = true;
      package = pkgs.docker_29;
    };

    system.stateVersion = "24.05";
  };
}
