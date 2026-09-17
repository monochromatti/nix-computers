{ ... }:
{
  flake.modules.nixos."host/firefly/hardware" = (
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages_7_2;
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
        nvidia.package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "595.91.07";
          sha256_64bit = "sha256-yiPIjdJLB6GRZE4eEc+3vN11NzBXSa9A+YABiwleYxM=";
          sha256_aarch64 = "sha256-fqkN7ONFXtTeXyu2mQxorrk362Epxq3bz88hhKYQzwQ=";
          openSha256 = "sha256-OB8Epd+qn/WywxsPiFpxEOAzlJqb6I1SyRoV3a8l71k=";
          settingsSha256 = "sha256-QzT8Cw1luuZGP9DUje3HN/0ngiayqHURj+bqPsxlJ5w=";
          persistencedSha256 = "sha256-3JQBaNmkwxvCXv9q8aHKas6VZM/JjLsuilC2t7ET0u0=";
        };
        bluetooth = {
          enable = true;
          powerOnBoot = true;
        };
        keyboard.zsa.enable = true;
      };
    }
  );
}
