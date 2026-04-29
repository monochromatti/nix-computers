{ ... }:
{
  flake.modules.nixos.firefly.imports = [
    {
      sops.secrets = {
        nixbuild-ssh = { };
        github-token = {
          key = "monochromatti/github-token";
        };
        password = {
          neededForUsers = true;
          key = "monochromatti/password";
        };
      };
    }
  ];
}
