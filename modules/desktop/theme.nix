{ config, inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  themeType = lib.types.submodule {
    options = {
      opacity = lib.mkOption {
        type = lib.types.float;
        description = "Opacity used by desktop applications.";
      };
      font = {
        sans = lib.mkOption {
          type = lib.types.str;
          description = "Sans-serif desktop font family.";
        };
        fixed = lib.mkOption {
          type = lib.types.str;
          description = "Fixed-width desktop font family.";
        };
        size = lib.mkOption {
          type = lib.types.ints.positive;
          description = "Desktop font size.";
        };
      };
      cursor = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Desktop cursor theme name.";
        };
        size = lib.mkOption {
          type = lib.types.ints.positive;
          description = "Desktop cursor size.";
        };
      };
      iconTheme = lib.mkOption {
        type = lib.types.str;
        description = "Desktop icon theme name.";
      };
      colorScheme = lib.mkOption {
        type = lib.types.str;
        description = "Desktop color scheme name.";
      };
    };
  };
in
{
  options.nixComputers = lib.mkOption {
    type = lib.types.submodule {
      options.theme = lib.mkOption { type = themeType; };
    };
    default = { };
  };

  config.nixComputers.theme = {
    opacity = lib.mkDefault 0.95;
    font = {
      sans = lib.mkDefault "Inter";
      fixed = lib.mkDefault "JetBrains Mono";
      size = lib.mkDefault 12;
    };
    cursor = {
      name = lib.mkDefault "Adwaita";
      size = lib.mkDefault 32;
    };
    iconTheme = lib.mkDefault "Papirus-Dark";
    colorScheme = lib.mkDefault "Nord";
  };
}
