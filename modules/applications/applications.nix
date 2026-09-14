{ ... }:
{
  flake.modules.hjem."feature/applications" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (lib.elem "apps" config.nixComputers.profileFeatures) {
      packages = with pkgs; [
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
    };

  flake.modules.homeManager."feature/applications" =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        wl-clipboard
        spotify
        kdePackages.okular
        libreoffice
        keymapp
        vlc
        inkscape
        gimp
        natscli
        nsc
        gpu-screen-recorder
        sqlite
      ];
    };
}
