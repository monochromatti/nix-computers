{ config, moduleWithSystem, ... }:
let
  theme = config.nixComputers.theme;
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.monstar = pkgs.callPackage ../../packages/terminal/monstar/package.nix { };
    };

  flake.modules.hjem."feature/monstar" =
    { config, lib, ... }:
    lib.mkIf (lib.elem "monstar" config.nixComputers.profileFeatures) {
      xdg.config.files."monstar/config" = {
        text = ''
          # Match the shared terminal font and spacing used by Ghostty.
          font-family = ${theme.font.fixed}
          font-size = ${toString theme.font.size}
          window-padding-x = 8
          window-padding-y = 8

          # Use the Nord variants already used by the desktop and editor themes.
          theme = light:Nord Light,dark:Nord
          background-opacity = ${toString theme.opacity}
          background-blur = true
          background-opacity-cells = true

          mouse-scroll-multiplier = precision:1,discrete:3
        '';
        clobber = true;
      };
    };

  flake.modules.nixos."feature/terminal/monstar" = moduleWithSystem (
    { config, ... }:
    { ... }:
    {
      environment.systemPackages = [ config.packages.monstar ];
    }
  );
}
