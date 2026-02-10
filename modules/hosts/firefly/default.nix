{ inputs, ... }:
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "firefly";

  flake.modules.nixos.firefly =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = with inputs.self.modules.nixos; [
        base
        secrets
        packages

        inputs.pc.nixosModules.hdw-hp-zbook-firefly_g11
        inputs.pc.nixosModules.default
        inputs.pc.nixosModules.docker
        inputs.utgard.nixosModules.aruba-onboard

        monochromatti
      ];

      swapDevices = [ { label = "swap"; } ];

      hardware = {
        nvidia.package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.production;
        keyboard.zsa.enable = true;
      };

      nixpkgs.overlays = [
        inputs.utgard.overlays.aruba-onboard
        inputs.utgard.overlays.ty
      ];

      environment.gnome.excludePackages = with pkgs; [
        gnome-weather
        gnome-music
        gnome-tour
        gnome-photos
      ];

      services = {
        displayManager.gdm.wayland = true;
        utgard.aruba-onboard.enable = true;
      };

      midgard.pc = {
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

      networking.extraHosts = ''
        127.0.4.1 tor
        127.0.5.1 rp1
        127.0.6.1 brage
      '';

      sops.secrets = {
        nixbuild-ssh = { };
        github-token = {
          key = "monochromatti/github-token";
        };
        password = {
          neededForUsers = true;
          key = "monochromatti/password";
        };
      };

      programs = {
        nix-ld = {
          enable = true;
          libraries = with pkgs; [
            stdenv.cc.cc.lib
          ];
        };
        niri.enable = true;
      };

      home-manager.users.monochromatti = {
        programs.fuzzel.enable = true;
      };

      virtualisation.docker.enable = true;

      system.stateVersion = "24.05";
    };
}
