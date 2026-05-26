{
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.limaHosts;

  mkLauncher =
    pkgs: upkgs: name: host:
    pkgs.writeShellApplication {
      name = host.packageName;
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
          guest_repo="/tmp/$(basename "$host_repo")"
          limactl shell --workdir / "$instance" -- rm -rf "$guest_repo"
          limactl copy --recursive "$host_repo" "$instance":/tmp/
          limactl shell --workdir / "$instance" -- sudo nixos-rebuild switch --flake "$guest_repo#${name}"
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
            exec limactl shell --workdir ${host.guestHome} "$instance" "$@"
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
            exec limactl shell --workdir ${host.guestHome} "$instance" "$@"
            ;;
        esac
      '';
    };

  darwinHosts = lib.filterAttrs (_: host: host.hostSystem == "aarch64-darwin") cfg;
in
{
  options.limaHosts = lib.mkOption {
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
            packageName = lib.mkOption {
              type = lib.types.str;
              default = name;
            };
            hostSystem = lib.mkOption { type = lib.types.str; };
            template = lib.mkOption {
              type = lib.types.str;
              default = "github:nixos-lima";
            };
            repoEnvVar = lib.mkOption {
              type = lib.types.str;
              default = "NIX_COMPUTERS_REPO";
            };
            guestHome = lib.mkOption { type = lib.types.str; };
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
        systemHosts = lib.filterAttrs (_: host: host.hostSystem == system) darwinHosts;
      in
      {
        packages = lib.mapAttrs' (
          name: host: lib.nameValuePair host.packageName (mkLauncher pkgs upkgs name host)
        ) systemHosts;

        apps = lib.mapAttrs' (
          _name: host:
          lib.nameValuePair host.packageName {
            type = "app";
            program = "${inputs.self.packages.${system}.${host.packageName}}/bin/${host.packageName}";
          }
        ) systemHosts;
      };

    flake.modules.darwin = lib.mapAttrs' (
      name: host:
      lib.nameValuePair name (
        { pkgs, upkgs, ... }:
        {
          environment.systemPackages = [
            inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.${host.packageName}
            upkgs.lima
          ];

          nix.linux-builder.enable = true;
          nix.settings.builders-use-substitutes = true;
        }
      )
    ) darwinHosts;
  };
}
