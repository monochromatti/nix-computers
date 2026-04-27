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

              window-rule {
                background-effect {
                  blur true
                }

                popups {
                  geometry-corner-radius 12
                  background-effect {
                    blur true
                  }
                }
              }

              layer-rule {
                background-effect {
                  blur true
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
