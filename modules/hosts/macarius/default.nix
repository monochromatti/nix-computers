{ config, ... }:
let
  flake = config.flake;
in
{
  flake.darwinConfigurations = flake.lib.mkDarwin "aarch64-darwin" "macarius";

  flake.modules.darwin."host/macarius" = { pkgs, ... }: {
    imports = [
      flake.modules.darwin."feature/base"
      flake.modules.darwin."feature/ai"
      flake.modules.darwin."profile/shell"
      flake.modules.darwin."feature/homebrew"
      flake.modules.darwin."feature/secrets"
      flake.modules.darwin."feature/hardware/zapp"
      flake.modules.darwin."feature/virtualization/lima-linux"

      flake.modules.darwin."user/monochromatti"
    ];

    sops.secrets.github-token = {
      key = "monochromatti/github-token";
    };

    system.stateVersion = 5;
  };
}
