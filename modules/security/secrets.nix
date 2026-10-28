{ config, ... }:
let
  flake = config.flake;
  secretsFile = ./secrets.yaml;
  nixAccessTokensPath = "/etc/nix/access-tokens.conf";
  users = flake.lib.users;

  mkSecretsModule =
    {
      primaryUser,
      userHome,
      tokensGroup,
    }:
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      environment.systemPackages = [ pkgs.secretspec ];

      sops.secrets.chatgpt-api-key = {
        key = "monochromatti/chatgpt-api-key";
        owner = primaryUser;
        mode = "0400";
        path = "/run/secrets/chatgpt-api-key";
      };

      sops = {
        age.keyFile = lib.mkForce "${userHome}/.config/sops/age/keys.txt";
        age.sshKeyPaths = [ ];
        gnupg.sshKeyPaths = [ ];
        defaultSopsFile = lib.mkForce secretsFile;

        templates."nix-access-tokens" = {
          content = ''
            access-tokens = github.com=${config.sops.placeholder.github-token}
          '';
          path = nixAccessTokensPath;
          owner = "root";
          group = tokensGroup;
          mode = "0640";
        };
      };
      nix.extraOptions = ''
        !include ${nixAccessTokensPath}
      '';
    };
in
{
  flake.modules.darwin."feature/secrets" =
    { config, pkgs, ... }:
    let
      primaryUser = config.system.primaryUser;
      userHome = users.${primaryUser}.home.darwin;
    in
    {
      imports = [
        (mkSecretsModule {
          inherit primaryUser userHome;
          tokensGroup = "staff";
        })
      ];
      home-manager.sharedModules = [ { home.packages = [ pkgs.sops ]; } ];
      environment.variables.SOPS_AGE_KEY_FILE = "${userHome}/.config/sops/age/keys.txt";
    };

  flake.modules.nixos."feature/secrets" =
    { config, ... }:
    let
      primaryUser = config.nixComputers.primaryUser;
    in
    {
      imports = [
        (mkSecretsModule {
          inherit primaryUser;
          userHome = users.${primaryUser}.home.linux;
          tokensGroup = "root";
        })
      ];
    };
}
