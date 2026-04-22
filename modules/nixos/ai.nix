{ inputs, ... }:
{
  flake.modules.nixos.ai =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.ai
      ];
    };
}
