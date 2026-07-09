{
  flake.modules.homeManager.apps =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
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
}
