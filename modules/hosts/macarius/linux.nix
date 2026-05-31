{ ... }:
{
  virtualization.lima.guests.linux = {
    instanceName = "linux";
    commandName = "linux-shell";
    workdir = "/Users/monochromatti";
    system = "aarch64-darwin";
  };
}
