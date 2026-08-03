{
  config,
  ...
}:
let
  flake = config.flake;
in
{
  flake.userPackageGroups.apps =
    pkgs: with pkgs; [
      # Terminal
      wl-clipboard

      # UI programs
      spotify
      kdePackages.okular
      libreoffice
      keymapp
      vlc

      # Graphics
      inkscape
      gimp

      # NATS
      natscli
      nsc

      # Other
      gpu-screen-recorder
      sqlite
    ];

  flake.modules.homeManager.apps =
    { pkgs, ... }:
    {
      home.packages = flake.userPackageGroups.apps pkgs;
    };
}
