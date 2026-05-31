{
  lib,
  config,
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
        pkgs.git
        upkgs.lima
      ];
      text = ''
        set -euo pipefail

        instance="${host.instanceName}"
        template="${host.template}"
        host_repo="''${${host.repoEnvVar}:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        bootstrap_marker="${host.bootstrapMarker}"

        if [ ! -f "$host_repo/flake.nix" ]; then
          echo "flake.nix not found in $host_repo" >&2
          echo "Run from repo root or set ${host.repoEnvVar}=/path/to/nix-computers" >&2
          exit 1
        fi

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
          limactl shell --workdir "$host_repo" "$instance" -- sudo nixos-rebuild switch --flake ".#${name}"
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
            shift
            ensure_started "$@"
            ;;
          shell|enter)
            shift
            ensure_started
            ensure_bootstrapped
            exec limactl shell --workdir ${host.workdir} "$instance" "$@"
            ;;
          rebuild)
            shift
            ensure_started
            apply_config
            ;;
          down|stop)
            shift
            exec limactl stop "$instance" "$@"
            ;;
          delete|destroy)
            shift
            exec limactl delete --force "$instance" "$@"
            ;;
          status)
            shift
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
            repoEnvVar = lib.mkOption {
              type = lib.types.str;
              default = "NIX_COMPUTERS_REPO";
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
