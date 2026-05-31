{
  flake.modules.homeManager.virtualization =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        qemu
      ];
    };
}
