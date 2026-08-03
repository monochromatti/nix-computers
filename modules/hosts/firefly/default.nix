{ config, inputs, ... }:
let
  flake = config.flake;
in
{
  flake.nixosConfigurations = flake.lib.mkNixos "x86_64-linux" "firefly";

  flake.modules.nixos."host/firefly" = { lib, pkgs, ... }: {
    imports = [
      flake.modules.nixos."feature/base"
      flake.modules.nixos."feature/ai"
      flake.modules.nixos."profile/shell"
      flake.modules.nixos."feature/secrets"
      flake.modules.nixos."feature/applications/obsidian"
      flake.modules.nixos."feature/hardware/zapp"
      flake.modules.nixos."feature/desktop/niri"
      flake.modules.nixos."feature/ghostty"
      flake.modules.nixos."feature/desktop/daily-hours"
      flake.modules.nixos."host/firefly/desktop"
      flake.modules.nixos."host/firefly/hardware"
      flake.modules.nixos."host/firefly/networking"
      flake.modules.nixos."host/firefly/secrets"
      flake.modules.nixos."host/firefly/tailscale"
      flake.modules.nixos."host/firefly/work"

      inputs.linear-notification-daemon.nixosModules.default
      inputs.pc.nixosModules.hdw-hp-zbook-firefly_g11
      inputs.pc.nixosModules.default
      inputs.pc.nixosModules.docker
      inputs.utgard.nixosModules.aruba-onboard

      flake.modules.nixos."user/monochromatti"
    ];

    hjem.users.monochromatti = {
      packages = lib.mkBefore [ pkgs.sops ];
      files.".ssh/config" = {
        text = ''
          Host *
            WarnWeakCrypto no
        '';
        clobber = true;
      };
      environment.sessionVariables.SOPS_AGE_KEY_FILE = "/home/monochromatti/.config/sops/age/keys.txt";
    };

    home-manager.users.monochromatti.fonts.fontconfig.enable = lib.mkForce false;

    nixpkgs.config.permittedInsecurePackages = [
      "electron-39.8.10"
    ];

    systemd.services.NetworkManager-wait-online.enable = false;

    boot.kernelModules.nvidia_uvm = lib.mkForce false;

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
      transmission_4
    ];

    services.mullvad-vpn.enable = true;

    # Keep background workloads running while securing session on lid close.
    services.logind.settings.Login = {
      HandleLidSwitch = "lock";
      HandleLidSwitchDocked = "lock";
      HandleLidSwitchExternalPower = "lock";
    };

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
      enableOnBoot = false;
      package = pkgs.docker_29;
    };

    system.stateVersion = "24.05";
  };
}
