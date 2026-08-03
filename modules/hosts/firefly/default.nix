{ config, inputs, ... }:
let
  flake = config.flake;
in
{
  flake.nixosConfigurations = flake.lib.mkNixos "x86_64-linux" "firefly";

  flake.modules.nixos.firefly = { lib, pkgs, ... }: {
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

    services.dbus.packages = [ (flake.desktop.ghostty.wrapper pkgs).wrapper ];

    hjem.users.monochromatti =
      let
        ghostty = flake.desktop.ghostty.wrapper pkgs;
        linuxFiles = flake.linuxConfigFiles { inherit pkgs; };
        gtkFiles = flake.gtkConfigFiles { inherit pkgs; };
        zedSettings = (pkgs.formats.json { }).generate "zed-user-settings" (
          flake.zedUserSettings { inherit lib pkgs; }
        );
        clobber = section: name: gtkFiles.${section}.${name} // { clobber = true; };
      in
      {
        packages = [
          ghostty.wrapper
          pkgs.sops
        ];
        environment.sessionVariables = {
          GTK2_RC_FILES = "/home/monochromatti/.gtkrc-2.0";
          XCURSOR_THEME = "Adwaita";
          XCURSOR_SIZE = 32;
          XCURSOR_PATH = [
            "/etc/profiles/per-user/monochromatti/share/icons"
            "/home/monochromatti/.icons"
            "/home/monochromatti/.local/share/icons"
          ];
          QT_QPA_PLATFORMTHEME = "qt6ct";
          SOPS_AGE_KEY_FILE = "/home/monochromatti/.config/sops/age/keys.txt";
        };
        files = {
          ".ssh/config" = {
            text = ''
              Host *
                WarnWeakCrypto no
            '';
            clobber = true;
          };
          ".gtkrc-2.0" = clobber "files" ".gtkrc-2.0";
          ".Xresources" = clobber "files" ".Xresources";
          ".icons/Adwaita" = clobber "files" ".icons/Adwaita";
          ".icons/default/index.theme" = clobber "files" ".icons/default/index.theme";
        };
        xdg.config.files = linuxFiles // {
          "zed/settings.json" = {
            source = zedSettings;
            clobber = true;
          };
          "gtk-3.0/settings.ini" = gtkFiles.xdgConfig."gtk-3.0/settings.ini" // {
            clobber = true;
          };
          "gtk-4.0/settings.ini" = gtkFiles.xdgConfig."gtk-4.0/settings.ini" // {
            clobber = true;
          };
          "gtk-4.0/gtk.css" = gtkFiles.xdgConfig."gtk-4.0/gtk.css" // {
            clobber = true;
          };
          "fontconfig/conf.d/10-hm-fonts.conf" = gtkFiles.xdgConfig."fontconfig/conf.d/10-hm-fonts.conf" // {
            clobber = true;
          };
          "fontconfig/conf.d/10-hm-rendering.conf" =
            gtkFiles.xdgConfig."fontconfig/conf.d/10-hm-rendering.conf"
            // {
              clobber = true;
            };
          "fontconfig/conf.d/52-hm-default-fonts.conf" =
            gtkFiles.xdgConfig."fontconfig/conf.d/52-hm-default-fonts.conf"
            // {
              clobber = true;
            };
          "vicinae/settings.json" = linuxFiles."vicinae/settings.json" // {
            clobber = true;
          };
          "qt6ct/qt6ct.conf" = linuxFiles."qt6ct/qt6ct.conf" // {
            clobber = true;
          };
          "systemd/user/app-com.mitchellh.ghostty.service" = {
            source = "${ghostty.wrapper}/share/systemd/user/app-com.mitchellh.ghostty.service";
            clobber = true;
          };
          "systemd/user/app-com.mitchellh.ghostty.service.d/overrides.conf" = {
            text = ''
              [Unit]
              X-Reload-Triggers=${ghostty.configFile.path}
              X-SwitchMethod=keep-old
            '';
            clobber = true;
          };
          "bat/syntaxes/ghostty.sublime-syntax" = {
            source = "${ghostty.wrapper}/share/bat/syntaxes/ghostty.sublime-syntax";
            clobber = true;
          };
          "bat/config" = {
            text = "--map-syntax='${ghostty.configFile.path}:Ghostty Config'\n";
            clobber = true;
          };
        };
        xdg.data.files = {
          "icons/Adwaita" = clobber "xdgData" "icons/Adwaita";
          "icons/default/index.theme" = clobber "xdgData" "icons/default/index.theme";
        };
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
