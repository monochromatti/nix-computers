{ config, ... }:
let
  theme = config.nixComputers.theme;
in
{
  flake.modules.hjem."feature/qt" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (lib.elem "qt" config.nixComputers.profileFeatures) {
      packages = [ pkgs.qt6Packages.qt6ct ];
      environment.sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";
      xdg.config.files."qt6ct/qt6ct.conf" = {
        text = ''
          [Appearance]
              color_scheme_path=${config.directory}/.config/qt6ct/colors/noctalia.conf
          custom_palette=true
              icon_theme=${theme.iconTheme}
          style=Fusion

          [Fonts]
              fixed="${theme.font.fixed},${toString theme.font.size},-1,5,400,0,0,0,0,0"
              general="${theme.font.sans},${toString theme.font.size},-1,5,400,0,0,0,0,0"
        '';
        clobber = true;
      };
    };
}
