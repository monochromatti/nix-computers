{
  lib,
  config,
  inputs,
  ...
}:
let
  flake = config.flake;
  cfg = config.virtualization.lima.guests;

  mkLauncher =
    pkgs: upkgs: name: host:
    pkgs.writeShellApplication {
      name = host.commandName;
      runtimeInputs = [
        pkgs.coreutils
        pkgs.nix
        upkgs.lima
      ];
      text = ''
        set -euo pipefail

        instance="${host.instanceName}"
        template="${host.template}"
        flake_ref=${lib.escapeShellArg inputs.self.outPath}
        bootstrap_marker="${host.bootstrapMarker}"

        if ! command -v limactl >/dev/null 2>&1; then
          echo "limactl not found in PATH." >&2
          exit 1
        fi

        ensure_started() {
          if [ -d "$HOME/.lima/$instance" ]; then
            limactl start "$instance"
          else
            limactl start --name "$instance" --yes "$template"
          fi
        }

        is_bootstrapped() {
          limactl shell --workdir / "$instance" -- test -f "$bootstrap_marker"
        }

        mark_bootstrapped() {
          limactl shell --workdir / "$instance" -- sudo mkdir -p "$(dirname "$bootstrap_marker")"
          limactl shell --workdir / "$instance" -- sudo touch "$bootstrap_marker"
        }

        apply_config() {
          echo "Building ${name} NixOS system from $flake_ref..."
          toplevel="$(nix --extra-experimental-features 'nix-command flakes' build --print-out-paths "$flake_ref#nixosConfigurations.${name}.config.system.build.toplevel" --no-link)"

          echo "Copying closure to Lima guest..."
          # Export/import avoids needing SSH details and keeps flake source out of the guest.
          mapfile -t closure < <(nix-store -qR "$toplevel")
          nix-store --export "''${closure[@]}" \
            | limactl shell --workdir / "$instance" -- sudo -n nix-store --import

          echo "Activating $toplevel inside Lima guest..."
          limactl shell --workdir / "$instance" -- sudo -n "$toplevel/bin/switch-to-configuration" switch
          mark_bootstrapped
        }

        ensure_bootstrapped() {
          if ! is_bootstrapped; then
            echo "First run: applying ${host.instanceName} config inside Lima guest..."
            apply_config
          fi
        }

        cmd="''${1:-shell}"

        case "$cmd" in
          up|start)
            [ "$#" -eq 0 ] || shift
            ensure_started "$@"
            ;;
          shell|enter)
            [ "$#" -eq 0 ] || shift
            ensure_started
            ensure_bootstrapped
            exec limactl shell --workdir ${host.workdir} "$instance" "$@"
            ;;
          rebuild)
            [ "$#" -eq 0 ] || shift
            ensure_started
            apply_config
            ;;
          down|stop)
            [ "$#" -eq 0 ] || shift
            exec limactl stop "$instance" "$@"
            ;;
          delete|destroy)
            [ "$#" -eq 0 ] || shift
            exec limactl delete --force "$instance" "$@"
            ;;
          status)
            [ "$#" -eq 0 ] || shift
            exec limactl list "$@"
            ;;
          *)
            ensure_started
            ensure_bootstrapped
            exec limactl shell --workdir ${host.workdir} "$instance" "$@"
            ;;
        esac
      '';
    };

  darwinGuests = lib.filterAttrs (_: guest: guest.system == "aarch64-darwin") cfg;
in
{
  options.virtualization.lima.guests = lib.mkOption {
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            instanceName = lib.mkOption {
              type = lib.types.str;
              default = name;
            };
            commandName = lib.mkOption {
              type = lib.types.str;
              default = name;
            };
            system = lib.mkOption { type = lib.types.str; };
            template = lib.mkOption {
              type = lib.types.str;
              default = "github:nixos-lima";
            };
            workdir = lib.mkOption { type = lib.types.str; };
            bootstrapMarker = lib.mkOption {
              type = lib.types.str;
              default = "/var/lib/${name}/bootstrap-v1";
            };
          };
        }
      )
    );
  };

  config = lib.mkIf (cfg != { }) {
    perSystem =
      {
        pkgs,
        upkgs,
        system,
        ...
      }:
      let
        systemGuests = lib.filterAttrs (_: guest: guest.system == system) darwinGuests;
      in
      {
        packages = lib.mapAttrs' (
          name: guest: lib.nameValuePair guest.commandName (mkLauncher pkgs upkgs name guest)
        ) systemGuests;

        apps = lib.mapAttrs' (
          _name: guest:
          lib.nameValuePair guest.commandName {
            type = "app";
            program = "${flake.packages.${system}.${guest.commandName}}/bin/${guest.commandName}";
            meta.description = "Manage and enter Lima instance ${guest.instanceName}";
          }
        ) systemGuests;
      };

    flake.modules.darwin = lib.mapAttrs' (
      name: guest:
      lib.nameValuePair "lima-${name}" (
        { pkgs, upkgs, ... }:
        {
          environment.systemPackages = [
            flake.packages.${pkgs.stdenv.hostPlatform.system}.${guest.commandName}
            upkgs.lima
          ];

          nix.linux-builder.enable = true;
          nix.settings.builders-use-substitutes = true;
        }
      )
    ) darwinGuests;
  };
}
