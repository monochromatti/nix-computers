{ ... }:
{
  flake.modules.nixos.firefly.imports = [
    {
      sops.secrets = {
        nixbuild-ssh = { };
        github-token = {
          key = "monochromatti/github-token";
        };
        linear-api-key = {
          key = "monochromatti/linear-api-key";
          owner = "monochromatti";
          mode = "0400";
        };
        password = {
          neededForUsers = true;
          key = "monochromatti/password";
        };
      };
    }
  ];
}
