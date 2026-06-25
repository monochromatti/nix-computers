{ ... }:
{
  flake.modules.nixos.firefly.imports = [
    (
      { pkgs, ... }:
      {
        services.tailscale = {
          enable = true;
          openFirewall = true;
          useRoutingFeatures = "client";
        };

        environment.systemPackages = [
          pkgs.tailscale
          (pkgs.writeShellApplication {
            name = "tailnet";
            runtimeInputs = [ pkgs.tailscale ];
            text = ''
              usage() {
                cat <<'EOF'
              Usage: tailnet <command>

              Commands:
                dev       Connect to dev tailnet
                prod      Connect to prod tailnet
                status    Show tailnet status
                reset     Log out of current tailnet
                ssh HOST  SSH to tailnet host

              Examples:
                tailnet dev
                tailnet ssh vidar-prod
              EOF
              }

              command="''${1:-}"
              shift || true

              case "$command" in
                dev)
                  sudo tailscale up --login-server=https://head.dev.fornybar.eviny.io --accept-dns=false --accept-routes=false "$@"
                  ;;
                prod)
                  sudo tailscale up --login-server=https://head.fornybar.eviny.io --accept-dns=false --accept-routes=false "$@"
                  ;;
                status)
                  tailscale status "$@"
                  ;;
                reset|logout)
                  sudo tailscale logout "$@"
                  ;;
                ssh)
                  exec ssh "$@"
                  ;;
                help|-h|--help|"")
                  usage
                  ;;
                *)
                  echo "Unknown command: $command" >&2
                  usage >&2
                  exit 2
                  ;;
              esac
            '';
          })
        ];

        environment.shellAliases = {
          tn = "tailnet";
        };
      }
    )
  ];
}
