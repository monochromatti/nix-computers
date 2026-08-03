{ ... }:
{
  virtualization.lima.guests.linux = {
    instanceName = "linux";
    commandName = "linux-shell";
    workdir = "/Users/monochromatti";
    arch = "x86_64";
    buildInGuest = true;
    flakePath = "/Users/monochromatti/Code/nix-computers";
    system = "aarch64-darwin";
  };
}
