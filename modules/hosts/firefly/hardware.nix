{ ... }:
{
  flake.modules.nixos.firefly.imports = [
    (
      { pkgs, lib, ... }:
      {
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_18;

        swapDevices = [ { label = "swap"; } ];

        hardware = {
          # nvidia.package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.production;
          bluetooth = {
            enable = true;
            powerOnBoot = true;
          };
          keyboard.zsa.enable = true;
        };
      }
    )
  ];
}
