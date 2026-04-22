{ ... }:
{
  flake.modules.homeManager.aliases = {
    home.shellAliases = {
      lg = "lazygit";
      zed = "zeditor .";
      sync-yggdrasil = ''
        gh repo sync && gh repo sync -b dev-base --force && gh repo sync -b dev --force
      '';
    };
  };
}
