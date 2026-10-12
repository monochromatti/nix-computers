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

      # Unlock encrypted root and swap
      boot.initrd.luks.devices = {
        "luks-02b68489-b80e-4bd3-9ecc-437c8a7f6efb" = {
          device = "/dev/disk/by-uuid/02b68489-b80e-4bd3-9ecc-437c8a7f6efb";
        };

        "luks-66eb5119-c864-4779-b708-4c64e4642634" = {
          device = "/dev/disk/by-uuid/66eb5119-c864-4779-b708-4c64e4642634";
        };
      };

      # EFI System Partition
      boot.loader.efi.efiSysMountPoint = "/boot";

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/B17D-7B52";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      # Encrypted root filesystem
      fileSystems."/" = {
        device = "/dev/disk/by-uuid/31af0c0e-7c39-49ec-9c99-16cc59339682";
        fsType = "ext4";
      };

      # Encrypted swap
      swapDevices = [
        {
          device = "/dev/mapper/luks-66eb5119-c864-4779-b708-4c64e4642634";
        }
      ];

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
