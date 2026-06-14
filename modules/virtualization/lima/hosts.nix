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
        pkgs.gh
        pkgs.nix
        (upkgs.lima.override { withAdditionalGuestAgents = true; })
      ];
      text = ''
        set -euo pipefail

        instance="${host.instanceName}"
        template="${host.template}"
        flake_ref=${lib.escapeShellArg inputs.self.outPath}
        guest_flake_ref=${lib.escapeShellArg host.flakePath}
        build_in_guest=${lib.boolToString host.buildInGuest}
        bootstrap_marker="${host.bootstrapMarker}"

        if ! command -v limactl >/dev/null 2>&1; then
          echo "limactl not found in PATH." >&2
          exit 1
        fi

        ensure_started() {
          if [ -d "$HOME/.lima/$instance" ]; then
            limactl start "$instance"
          else
            limactl start --name "$instance" --arch ${lib.escapeShellArg host.arch} --yes "$template"
          fi
        }

        github_nix_config() {
          local token
          if token="$(gh auth token --hostname github.com 2>/dev/null)" && [ -n "$token" ]; then
            printf 'access-tokens = github.com=%s' "$token"
          fi
        }

        lima_shell() {
          local workdir="$1"
          shift
          local nix_config
          nix_config="$(github_nix_config)"

          if [ -n "$nix_config" ]; then
            if [ "$#" -eq 0 ]; then
              # Expand SHELL inside guest, not on host.
              # shellcheck disable=SC2016
              limactl shell --workdir "$workdir" "$instance" -- env NIX_CONFIG="$nix_config" sh -lc 'exec "$SHELL" -l'
            else
              limactl shell --workdir "$workdir" "$instance" -- env NIX_CONFIG="$nix_config" "$@"
            fi
          else
            limactl shell --workdir "$workdir" "$instance" "$@"
          fi
        }

        is_bootstrapped() {
          lima_shell / test -f "$bootstrap_marker"
        }

        mark_bootstrapped() {
          lima_shell / sudo mkdir -p "$(dirname "$bootstrap_marker")"
          printf '%s\n' "$1" \
            | lima_shell / sudo tee "$bootstrap_marker" >/dev/null
        }

        enter_shell() {
          if lima_shell / test -d ${lib.escapeShellArg host.workdir}; then
            lima_shell ${lib.escapeShellArg host.workdir} "$@"
          else
            echo "Workdir ${host.workdir} is unavailable inside Lima guest; entering /." >&2
            lima_shell / "$@"
          fi
        }

        apply_config() {
          if [ "$build_in_guest" = true ]; then
            echo "Building ${name} NixOS system inside Lima guest from $guest_flake_ref..."
            toplevel="$(lima_shell / nix --extra-experimental-features 'nix-command flakes' build --print-out-paths "$guest_flake_ref#nixosConfigurations.${name}.config.system.build.toplevel" --no-link)"
          else
            echo "Building ${name} NixOS system from $flake_ref..."
            toplevel="$(nix --extra-experimental-features 'nix-command flakes' build --print-out-paths "$flake_ref#nixosConfigurations.${name}.config.system.build.toplevel" --no-link)"

            echo "Copying closure to Lima guest..."
            # Export/import avoids needing SSH details and keeps flake source out of the guest.
            mapfile -t closure < <(nix-store -qR "$toplevel")
            nix-store --export "''${closure[@]}" \
              | lima_shell / sudo -n nix-store --import >/dev/null
          fi

          echo "Installing $toplevel as next boot inside Lima guest..."
          lima_shell / sudo -n "$toplevel/bin/switch-to-configuration" boot

          echo "Restarting Lima guest to activate config..."
          limactl restart "$instance"

          echo "Verifying booted system..."
          booted="$(lima_shell / readlink -f /run/current-system)"
          if [ "$booted" != "$toplevel" ]; then
            echo "Expected /run/current-system to be $toplevel, got $booted" >&2
            exit 1
          fi

          mark_bootstrapped "$toplevel"
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
            enter_shell "$@"
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
            enter_shell "$@"
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
            arch = lib.mkOption {
              type = lib.types.enum [
                "x86_64"
                "aarch64"
                "riscv64"
                "armv7l"
                "s390x"
                "ppc64le"
              ];
              default = "aarch64";
            };
            buildInGuest = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            flakePath = lib.mkOption {
              type = lib.types.str;
              default = inputs.self.outPath;
            };
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
            (upkgs.lima.override { withAdditionalGuestAgents = true; })
          ];

          nix.linux-builder.enable = true;
          nix.settings.builders-use-substitutes = true;
        }
      )
    ) darwinGuests;
  };
}
