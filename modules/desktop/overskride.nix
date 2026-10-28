{ ... }:
{
  flake.modules.hjem."feature/overskride" =
    {
      pkgs,
      ...
    }:
    {
      packages = [ pkgs.overskride ];
      systemd.services.overskride = {
        description = "Overskride Bluetooth manager";
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.overskride}/bin/overskride";
          Restart = "on-failure";
          RestartSec = 2;
        };
        wantedBy = [ "graphical-session.target" ];
      };
      xdg.config.files = {
        "systemd/user/overskride.service".clobber = true;
        "systemd/user/graphical-session.target.wants/overskride.service".clobber = true;
      };
    };
}
