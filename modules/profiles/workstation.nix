{ config, ... }:
let
  flake = config.flake;
in
{
  flake.modules.homeManager.workstation = {
    imports = with flake.modules.homeManager; [
      development
      hunk
      terminal
      documents
      publishing
      diagrams
      containers
      cloud
      virtualization
    ];
  };
}
