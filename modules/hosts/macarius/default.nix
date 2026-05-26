{ inputs, ... }:
{
  imports = [ ./homunculus.nix ];

  flake.darwinConfigurations = inputs.self.lib.mkDarwin "aarch64-darwin" "macarius";

  flake.modules.darwin.macarius = {
    imports = [
      inputs.self.modules.darwin.base
      inputs.self.modules.darwin.shell
      inputs.self.modules.darwin.homebrew
      inputs.self.modules.darwin.secrets
      inputs.self.modules.darwin.hardware
      inputs.self.modules.darwin.homunculus

      inputs.self.modules.darwin.monochromatti
    ];

    sops.secrets.github-token = {
      key = "monochromatti/github-token";
    };

    system.stateVersion = 5;
  };
}
