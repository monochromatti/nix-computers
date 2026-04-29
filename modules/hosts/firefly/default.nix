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

      environment.systemPackages = with pkgs; [
        overskride
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

      networking.extraHosts = ''
        127.0.4.1 tor
        127.0.5.1 rp1
        127.0.6.1 brage
      '';

      environment.shellAliases = {
        start-vidar-prod = ''
          az vm start --subscription 584a2d66-5adc-45d5-b796-9d69d54154d6 --resource-group asgard --name vidar
        '';
        stop-vidar-prod = ''
          az vm deallocate --subscription 584a2d66-5adc-45d5-b796-9d69d54154d6 --resource-group asgard --name vidar
        '';
        start-vidar-dev = ''
          az vm start --subscription 5111c8c6-28f3-4b11-a07f-0aef3ed4721d --resource-group asgard --name vidar
        '';
        stop-vidar-dev = ''
          az vm deallocate --subscription 5111c8c6-28f3-4b11-a07f-0aef3ed4721d --resource-group asgard --name vidar
        '';
      };

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

      midgard.niri.settings = lib.recursiveUpdate inputs.self.desktop.niri.settings inputs.self.desktop.niri.hostSettings.firefly;

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
        systemd.user.services.overskride = {
          Unit = {
            Description = "Overskride Bluetooth manager";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = "${pkgs.overskride}/bin/overskride";
            Restart = "on-failure";
            RestartSec = 2;
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };
      };

      virtualisation.docker.enable = true;

      system.stateVersion = "24.05";
    };
}
