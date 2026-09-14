{ config, ... }:
let
  flake = config.flake;
  secretsFile = ./secrets.yaml;
  nixAccessTokensPath = "/etc/nix/access-tokens.conf";
  users = flake.lib.users;

  secretsModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    with lib;
    let
      primaryUser =
        if pkgs.stdenv.isDarwin then config.system.primaryUser else config.nixComputers.primaryUser;
      userHome =
        if pkgs.stdenv.isDarwin then users.${primaryUser}.home.darwin else users.${primaryUser}.home.linux;
    in
    {
      config = {
        environment.systemPackages = [ pkgs.secretspec ];

        home-manager.sharedModules = lib.optional pkgs.stdenv.isDarwin {
          home.packages = [ pkgs.sops ];
        };

        environment.variables = lib.mkIf pkgs.stdenv.isDarwin {
          SOPS_AGE_KEY_FILE = "${userHome}/.config/sops/age/keys.txt";
        };

        sops.secrets.chatgpt-api-key = {
          key = "monochromatti/chatgpt-api-key";
          owner = primaryUser;
          mode = "0400";
          path = "/run/secrets/chatgpt-api-key";
        };

        sops = {
          age.keyFile = mkForce "${userHome}/.config/sops/age/keys.txt";
          age.sshKeyPaths = [ ];
          gnupg.sshKeyPaths = [ ];
          defaultSopsFile = mkForce secretsFile;

          templates."nix-access-tokens" = {
            content = ''
              access-tokens = github.com=${config.sops.placeholder.github-token}
            '';
            path = nixAccessTokensPath;
            owner = "root";
            group = if pkgs.stdenv.isDarwin then "staff" else "root";
            mode = "0640";
          };
        };
        nix.extraOptions = ''
          !include ${nixAccessTokensPath}
        '';
      };
    };
in
{
  flake.modules.darwin."feature/secrets" = secretsModule;
  flake.modules.nixos."feature/secrets" = secretsModule;
}
