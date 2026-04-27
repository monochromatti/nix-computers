{ inputs, self, ... }:
{
  perSystem =
    {
      pkgs,
      upkgs,
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
            userNoctaliaConfig = "${self.lib.users.monochromatti.home.linux}/.config/niri/noctalia.kdl";
            niri = inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system}.niri;
            settings = self.desktop.niri.settings;
            defaultConfig = pkgs.writeText "niri-default-config.kdl" (
              builtins.replaceStrings [ "spawn-at-startup \"waybar\"" ] [ "// spawn-at-startup \"waybar\"" ] (
                builtins.readFile "${niri.src}/resources/default-config.kdl"
              )
            );
            base = inputs.wrappers.wrapperModules.niri.apply {
              inherit pkgs settings;
              package = lib.mkForce niri;
            };
            mainConfig = pkgs.writeText "niri-main-config.kdl" ''
              include "${defaultConfig}"
              include "${base."config.kdl".path}"

              layout {
                background-color "transparent"
              }

              blur {
                passes 2
                offset 3.0
                noise 0.03
                saturation 1.0
              }

              window-rule {
                match app-id="^com\\.mitchellh\\.ghostty$"
                draw-border-with-background false

                background-effect {
                  blur true
                }
              }

              window-rule {
                match app-id="^dev\\.zed\\.Zed$"
                draw-border-with-background false

                background-effect {
                  blur true
                }
              }

              layer-rule {
                match layer="top"
                match layer="overlay"

                background-effect {
                  xray false
                }
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
