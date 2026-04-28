{ ... }:
let
  aliasesModule = {
    environment.shellAliases = {
      lg = "lazygit";
      zed = "zeditor .";
      sync-yggdrasil = ''
        gh repo sync && gh repo sync -b dev-base --force && gh repo sync -b dev --force
      '';
    };
  };
in
{
  flake.modules.darwin.shellAliases = aliasesModule;
  flake.modules.nixos.shellAliases = aliasesModule;
}
