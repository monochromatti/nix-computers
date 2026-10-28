{ config, inputs, ... }:
let
  flake = config.flake;
  theme = config.nixComputers.theme;
  sharedSettings = {
    font-family = [
      theme.font.fixed
      "DroidSansM Nerd Font Mono"
    ];
    window-padding-x = 8;
    window-padding-y = 8;
    cursor-style = "block";
    background-opacity = theme.opacity;
    background-opacity-cells = true;
  };
  linuxSettings = sharedSettings // {
    font-size = theme.font.size;
  };
  mkWrapper =
    pkgs:
    inputs.wrappers.wrapperModules.ghostty.apply {
      inherit pkgs;
      settings = linuxSettings;
      configFile.content = inputs.nixpkgs.lib.generators.toKeyValue {
        listsAsDuplicateKeys = true;
      } linuxSettings;
      filesToPatch = inputs.nixpkgs.lib.mkAfter [ "share/applications/*.desktop" ];
    };
  ghosttyFiles =
    { pkgs }:
    let
      ghostty = mkWrapper pkgs;
    in
    {
      "systemd/user/app-com.mitchellh.ghostty.service" = {
        source = "${ghostty.wrapper}/share/systemd/user/app-com.mitchellh.ghostty.service";
        clobber = true;
      };
      "systemd/user/app-com.mitchellh.ghostty.service.d/overrides.conf" = {
        text = ''
          [Unit]
          X-Reload-Triggers=${ghostty.configFile.path}
          X-SwitchMethod=keep-old
        '';
        clobber = true;
      };
      "bat/syntaxes/ghostty.sublime-syntax" = {
        source = "${ghostty.wrapper}/share/bat/syntaxes/ghostty.sublime-syntax";
        clobber = true;
      };
      "bat/config" = {
        text = "--map-syntax='${ghostty.configFile.path}:Ghostty Config'\n";
        clobber = true;
      };
    };
in
{
  flake.modules.nixos."feature/ghostty" =
    {
      pkgs,
      ...
    }:
    {
      services.dbus.packages = [ (mkWrapper pkgs).wrapper ];
      home-manager.sharedModules = [ flake.modules.homeManager."feature/ghostty/shell-integration" ];
    };

  flake.modules.hjem."feature/ghostty" =
    {
      lib,
      pkgs,
      ...
    }:
    {
      packages = lib.mkBefore [ (mkWrapper pkgs).wrapper ];
      xdg.config.files = ghosttyFiles { inherit pkgs; };
    };

  flake.modules.homeManager."feature/ghostty" =
    { pkgs, ... }:
    {
      xdg.enable = true;
      programs.ghostty = {
        enable = true;
        package = pkgs.ghostty-bin;
        settings = sharedSettings // {
          # Keep macOS Ghostty text larger than shared desktop font size.
          font-size = 16;
          background-blur = "macos-glass-regular";
          macos-titlebar-style = "transparent";
        };
      };
    };

  flake.modules.homeManager."feature/ghostty/shell-integration" =
    { lib, ... }:
    {
      programs.bash.initExtra = lib.mkOrder 101 ''
        if [[ -n "''${GHOSTTY_RESOURCES_DIR}" ]]; then builtin source "''${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"; fi
      '';
      programs.fish.interactiveShellInit = ''
        if set -q GHOSTTY_RESOURCES_DIR; source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"; end
      '';
      programs.zsh.initContent = ''
        if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration; fi
      '';
    };

  perSystem =
    { pkgs, ... }:
    {
      packages = pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
        ghostty = (mkWrapper pkgs).wrapper;
      };
    };
}
