{ config, ... }:
let
  flake = config.flake;
in
{
  imports = [ ./linux.nix ];

  flake.darwinConfigurations = flake.lib.mkDarwin "aarch64-darwin" "macarius";

  flake.modules.darwin.macarius = { pkgs, ... }: {
    imports = [
      flake.modules.darwin.base
      flake.modules.darwin.shell
      flake.modules.darwin.homebrew
      flake.modules.darwin.secrets
      flake.modules.darwin.hardware
      flake.modules.darwin."lima-linux"

      flake.modules.darwin.monochromatti
    ];

    environment.systemPackages = with pkgs; [
      proton-vpn-cli
    ];

    sops.secrets.github-token = {
      key = "monochromatti/github-token";
    };

    system.stateVersion = 5;
  };
}
