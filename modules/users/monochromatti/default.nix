{ inputs, ... }:
let
  username = "monochromatti";
  users = inputs.self.lib.users;
in
{
  flake.modules.homeManager.${username} =
    { ... }:
    {
      imports =
        (with inputs.self.modules.homeManager; [
          packages
          shell
          zed
          aliases
        ])
        ++ [
          inputs.agents.homeModules.codex
          inputs.agents.homeModules.opencode
          inputs.agents.homeModules."claude-code"
          inputs.agents.homeModules.pi
        ];

      xdg.enable = true;

      programs.fornybar.codex.enable = true;
      programs.fornybar.opencode.enable = true;
      programs.fornybar."claude-code".enable = true;
      programs.fornybar.pi = {
        enable = true;
        extensions = [
          "npm:pi-amplike"
          "npm:pi-mcp-adapter"
          "npm:pi-ask-user"
          "npm:pi-move-session"
          "npm:pi-markdown-preview"
        ];
      };

      home = {
        inherit username;
        stateVersion = "24.05";
        shellAliases = {
          sync-yggdrasil = ''
            gh repo sync && gh repo sync -b dev-base --force && gh repo sync -b dev --force
          '';
        };
      };
    };

  flake.modules.nixos.${username} =
    { ... }:
    {
      home-manager.sharedModules = [
        inputs.self.modules.homeManager.${username}
      ];

      home-manager.users.${username} = {
        home = {
          homeDirectory = users.${username}.home.linux;
          shellAliases = {
            start-vidar-prod = ''
              az vm start --subscription 584a2d66-5adc-45d5-b796-9d69d54154d6 --resource-group asgard --name vidar
            '';
            stop-vidar-prod = ''
              az vm deallocate --subscription 584a2d66-5adc-45d5-b796-9d69d54154d6 --resource-group asgard --name vidar
            '';
            start-vidar-dev = ''
              az vm start --subscription 5111c8c6-28f3-4b11-a07f-0aef3ed4721d --resource-group asgard --name vidar
            '';
            stop-vidar-dev = ''
              az vm deallocate --subscription 5111c8c6-28f3-4b11-a07f-0aef3ed4721d --resource-group asgard --name vidar
            '';
          };
        };
        xdg.configFile."user-dirs.dirs".source = ../../../dotfiles/user-dirs.dirs;
      };
    };

  flake.modules.darwin.${username} =
    { ... }:
    {
      home-manager.sharedModules = [
        inputs.self.modules.homeManager.${username}
      ];

      users.users.${username} = {
        name = username;
        home = users.${username}.home.darwin;
      };

      system.primaryUser = username;

      home-manager.users.${username} = { };
    };
}
