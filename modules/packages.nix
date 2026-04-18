{ inputs, self, ... }:
{
  perSystem =
    {
      pkgs,
      upkgs,
      config,
      ...
    }:
    {
      packages = pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
        noctalia-shell = inputs.wrappers.lib.wrapPackage {
          inherit pkgs;
          package = upkgs.noctalia-shell;
        };

        niri =
          let
            lib = pkgs.lib;
            noctaliaExe = lib.getExe config.packages.noctalia-shell;
            userNoctaliaConfig = "${self.lib.users.monochromatti.home.linux}/.config/niri/noctalia.kdl";
            settings = self.desktop.niri.settings // {
              spawn-at-startup = [ noctaliaExe ];
            };
            defaultConfig = pkgs.writeText "niri-default-config.kdl" (
              builtins.replaceStrings [ "spawn-at-startup \"waybar\"" ] [ "// spawn-at-startup \"waybar\"" ] (
                builtins.readFile "${pkgs.niri.src}/resources/default-config.kdl"
              )
            );
            base = inputs.wrappers.wrapperModules.niri.apply {
              inherit pkgs settings;
            };
            mainConfig = pkgs.writeText "niri-main-config.kdl" ''
              include "${defaultConfig}"
              include "${base."config.kdl".path}"

              layout {
                background-color "transparent"
              }

              layer-rule {
                match namespace="^noctalia-wallpaper*"
                place-within-backdrop true
              }

              layer-rule {
                match namespace="^noctalia-overview*"
                place-within-backdrop true
              }

              include "${userNoctaliaConfig}"
            '';
          in
          (base.apply {
            env.NIRI_CONFIG = lib.mkForce (toString mainConfig);
          }).wrapper;
      };
    };
}
