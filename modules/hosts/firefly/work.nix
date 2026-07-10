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

        environment.shellAliases = {
          start-vidar-prod = ''
            az vm start --subscription 584a2d66-5adc-45d5-b796-9d69d54154d6 --resource-group asgard --name vidar
          '';
          stop-vidar-prod = ''
            az vm deallocate --subscription 584a2d66-5adc-45d5-b796-9d69d54154d6 --resource-group asgard --name vidar
          '';
          start-vidar-dev = ''
            az vm start --subscription 5111c8c6-28f3-4b11-a07f-0aef3ed4721d --resource-group asgard --name vidar
          '';
          stop-vidar-dev = ''
            az vm deallocate --subscription 5111c8c6-28f3-4b11-a07f-0aef3ed4721d --resource-group asgard --name vidar
          '';
        };
      }
    )
  ];
}
