{ ... }:
{
  flake.modules.nixos."host/firefly/tailscale" =
    { lib, pkgs, ... }:
    let
      ensureAsgardKey = pkgs.writeShellApplication {
        name = "ensure-asgard-key";
        runtimeInputs = with pkgs; [
          azure-cli
          gawk
          gnugrep
          jq
          openssh
        ];
        text = ''
          keyfile="$(mktemp)"
          trap 'rm -f "$keyfile"' EXIT

          if ssh-add -L 2>/dev/null | awk -F ' ' '{ print $3 }' | grep -q "fornybar-dataflyt"; then
            exit 0
          fi

          az keyvault secret show \
            --id "https://dataflyt584a2d66.vault.azure.net/secrets/ssh-asgard/5a2df18d03504fed823916ff9b4f0d2d" \
            | jq -r '.value' > "$keyfile"

          ssh-add "$keyfile"
        '';
      };
    in
    {
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
            sshUser = "odin";
            sshLoadKeyCommand = "${ensureAsgardKey}/bin/ensure-asgard-key";
          };
          prod = {
            loginServer = "https://head.fornybar.eviny.io";
            sshUser = "odin";
            sshLoadKeyCommand = "${ensureAsgardKey}/bin/ensure-asgard-key";
          };
        };
      };

      programs.ssh = {
        enableAskPassword = true;
        askPassword = lib.getExe pkgs.lxqt.lxqt-openssh-askpass;
      };

      environment.shellAliases.tn = "ts";
    };
}
