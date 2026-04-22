{ inputs, ... }:
let
  username = "monochromatti";
  users = inputs.self.lib.users;
in
{
  flake.modules.homeManager.${username} = {
    imports = with inputs.self.modules.homeManager; [
      packages
      zed
      agents
      linux
      userdirs
    ];

    programs.home-manager.enable = true;

    home = {
      inherit username;
      stateVersion = "24.05";
    };
  };

  flake.modules.nixos.${username} =
    { ... }:
    {
      home-manager.sharedModules = [
        inputs.self.modules.homeManager.${username}
      ];

      home-manager.users.${username}.home.homeDirectory = users.${username}.home.linux;
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
