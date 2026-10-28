{ ... }:
{
  flake.modules.hjem."feature/applications" =
    {
      pkgs,
      ...
    }:
    {
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
        qimgv

        # NATS
        natscli
        nsc

        # Other
        gpu-screen-recorder
        sqlite
      ];
      xdg.config.files."mimeapps.list" = {
        text = ''
          [Default Applications]
          x-scheme-handler/bitwarden=bitwarden.desktop
          text/html=google-chrome.desktop
          x-scheme-handler/http=google-chrome.desktop
          x-scheme-handler/https=google-chrome.desktop
          x-scheme-handler/about=google-chrome.desktop
          x-scheme-handler/unknown=google-chrome.desktop
          image/bmp=qimgv.desktop;
          image/gif=qimgv.desktop;
          image/jpeg=qimgv.desktop;
          image/png=qimgv.desktop;
          image/tiff=qimgv.desktop;
          image/webp=qimgv.desktop;

          [Added Associations]
        '';
        clobber = true;
      };
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
