{ inputs, ... }:
{
  flake.modules.darwin.ai =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.ai
      ];
    };
}
