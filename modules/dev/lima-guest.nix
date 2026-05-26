{ inputs, ... }:
{
  flake.modules.nixos.lima =
    {
      lib,
      modulesPath,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.nixos-lima.nixosModules.lima
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      services.lima.enable = true;
      services.openssh.enable = true;

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [ "@wheel" ];
      };

      boot = {
        kernelPackages = pkgs.linuxPackages_latest;
        kernelParams = [ "console=tty0" ];
        loader.grub = {
          device = "nodev";
          efiSupport = true;
          efiInstallAsRemovable = true;
        };
      };

      fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        autoResize = true;
        fsType = "ext4";
        options = [
          "noatime"
          "nodiratime"
          "discard"
        ];
      };

      fileSystems."/boot" = {
        device = lib.mkForce "/dev/vda1";
        fsType = "vfat";
      };
    };
}
