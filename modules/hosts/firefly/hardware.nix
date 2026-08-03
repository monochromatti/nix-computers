{ ... }:
{
  flake.modules.nixos."host/firefly/hardware" = (
    { pkgs, lib, ... }:
    {
      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_18;
      boot.loader.efi.efiSysMountPoint = "/boot/efi";

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/053849ba-b8f4-4350-9ebe-a36b49abe87c";
        fsType = "ext4";
      };

      fileSystems."/boot/efi" = {
        device = "/dev/disk/by-uuid/9834-9FCB";
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
        ];
      };

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
  );
}
