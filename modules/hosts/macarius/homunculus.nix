{ ... }:
{
  imports = [ ../../dev/lima-hosts.nix ];

  limaHosts.homunculus = {
    instanceName = "homunculus";
    packageName = "homunculus-shell";
    guestHome = "/Users/monochromatti";
    hostSystem = "aarch64-darwin";
  };
}
