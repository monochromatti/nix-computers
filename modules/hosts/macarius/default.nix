{ inputs, ... }:
{
  flake.darwinConfigurations = inputs.self.lib.mkDarwin "aarch64-darwin" "macarius";

  flake.modules.darwin.macarius = {
    imports = with inputs.self.modules.darwin; [
      base
      shell
      homebrew
      secrets
      hardware

      monochromatti
    ];

    sops.secrets.github-token = {
      key = "monochromatti/github-token";
    };

    system.stateVersion = 5;
  };
}
