{ ... }:
{
  flake.modules.homeManager.aliases = {
    home.shellAliases = {
      lg = "lazygit";
      zed = "zeditor .";
    };
  };
}
