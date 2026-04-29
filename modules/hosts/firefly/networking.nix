{ ... }:
{
  flake.modules.nixos.firefly.imports = [
    {
      networking.extraHosts = ''
        127.0.4.1 tor
        127.0.5.1 rp1
        127.0.6.1 brage
      '';
    }
  ];
}
