{ ... }:
{
  flake.modules.nixos."host/firefly/tailscale" = {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "client";
    };

    midgard.pc.tailscale = {
      enable = true;
      tailnets = {
        dev = {
          loginServer = "https://head.dev.fornybar.eviny.io";
          acceptDns = false;
          sshUser = "odin";
        };
        prod = {
          loginServer = "https://head.fornybar.eviny.io";
          acceptDns = false;
          sshUser = "odin";
        };
      };
    };

    environment.shellAliases.tn = "ts";
  };
}
