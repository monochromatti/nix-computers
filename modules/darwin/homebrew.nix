{ ... }:
{
  flake.modules.darwin.homebrew = {
    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = true;
        upgrade = true;
        cleanup = "zap";
      };
      brews = [ "tw93/tap/mole" ];
      casks = [
        "discord"
        "zotero"
        "affinity-designer"
        "affinity-photo"
        "affinity-publisher"
        "spotify"
        "obsidian"
        "raycast"
        "zoom"
        "vlc"
        "transmission"
        "keka"
        "soundsource"
        "visual-studio-code"
        "loop"
        "mullvad-vpn"
        "protonvpn"
        "bitwarden"
      ];
    };
  };
}
