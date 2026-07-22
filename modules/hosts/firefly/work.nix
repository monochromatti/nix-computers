{ inputs, ... }:
{
  flake.modules.nixos.firefly.imports = [
    (
      { pkgs, ... }:
      {
        nixpkgs.overlays = [
          inputs.utgard.overlays.aruba-onboard
        ];

        services.utgard.aruba-onboard.enable = true;

        programs.nix-ld = {
          enable = true;
          libraries = with pkgs; [
            stdenv.cc.cc.lib
          ];
        };

        environment.systemPackages = [
          (pkgs.writeShellApplication {
            name = "start-vm";
            runtimeInputs = [ pkgs.azure-cli ];
            text = ''
              if [ "$#" -ne 2 ]; then
                echo "usage: start-vm <machine> <env>" >&2
                exit 2
              fi

              machine="$1"
              env="$2"

              case "$env" in
                prod)
                  subscription="584a2d66-5adc-45d5-b796-9d69d54154d6"
                  ;;
                dev)
                  subscription="5111c8c6-28f3-4b11-a07f-0aef3ed4721d"
                  ;;
                *)
                  echo "unknown env: $env" >&2
                  echo "expected: prod, dev" >&2
                  exit 2
                  ;;
              esac

              az vm start --subscription "$subscription" --resource-group asgard --name "$machine"
            '';
          })
        ];
      }
    )
  ];
}
