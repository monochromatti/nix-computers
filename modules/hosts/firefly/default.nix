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

      boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_18;

      swapDevices = [ { label = "swap"; } ];

      hardware = {
        # nvidia.package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.production;
        bluetooth = {
          enable = true;
          powerOnBoot = true;
        };
        keyboard.zsa.enable = true;
      };

      nixpkgs.overlays = [
        inputs.utgard.overlays.aruba-onboard
        inputs.utgard.overlays.ty
      ];

      services = {
        blueman.enable = true;
        greetd = {
          enable = true;
          settings = {
            default_session.command = ''
              ${pkgs.tuigreet}/bin/tuigreet \
                --time \
                --asterisks \
                --user-menu \
                --cmd niri-session
            '';
          };
        };
        utgard.aruba-onboard.enable = true;
      };

      environment.etc."greetd/environments".text = ''
        niri-session
      '';

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
        niri = {
          enable = true;
          package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.niri;
        };
      };

      home-manager.users.monochromatti = {
        programs.fuzzel.enable = true;
      };

      virtualisation.docker.enable = true;

      system.stateVersion = "24.05";
    };
}
