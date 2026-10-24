{ inputs, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      skill = "${self}/.agents/skills/testing-without-tautologies";
    in
    {
      packages.tautology-triage = pkgs.writeShellApplication {
        name = "tautology-triage";
        runtimeInputs = with pkgs; [
          curl
          jq
          python3
          coreutils
          inputs.agents.packages.${pkgs.stdenv.hostPlatform.system}.aienv
        ];
        runtimeEnv.TAUTOLOGY_SKILL = "${skill}/SKILL.md";
        text = builtins.readFile "${skill}/triage.sh";
      };
    };
}
