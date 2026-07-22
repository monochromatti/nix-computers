{ inputs, self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;

      baseSettingsModule = {
        config = {
          mcp = {
            enabled = [
              "linear"
              "playwright"
              "remarkable"
            ];
            registry.playwright = {
              transport = "stdio";
              command = "npx";
              args = [
                "-y"
                "@playwright/mcp@latest"
              ]
              ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                "--executable-path"
                (lib.getExe pkgs.chromium)
              ];
            };
            registry.remarkable = {
              transport = "stdio";
              command = lib.getExe pkgs.uv;
              args = [
                "tool"
                "run"
                "remarkable-mcp"
                "--usb"
              ];
            };
          };

          settings = {
            defaultProvider = "azure-openai-responses";
            defaultModel = "gpt-5.6-luna";
            defaultThinkingLevel = "high";
          };
        };
      };

      mkSkillsFromDirectory =
        skillsDir:
        builtins.listToAttrs (
          map
            (
              skillFile:
              let
                skillPath = dirOf skillFile;
                name = builtins.unsafeDiscardStringContext (baseNameOf skillPath);
              in
              lib.nameValuePair name {
                inherit name;
                description = null;
                path = skillPath;
                enable = true;
              }
            )
            (
              builtins.filter (path: baseNameOf path == "SKILL.md") (lib.filesystem.listFilesRecursive skillsDir)
            )
        );

      bundledSkills = mkSkillsFromDirectory "${inputs.agents}/.agents/skills";
      localSkills = mkSkillsFromDirectory "${self}/.agents/skills";

      ompSkills = lib.mapAttrs (_: _: { enable = true; }) bundledSkills // localSkills;

      linkLocalSkills = ''
        local_skills_dir="$HOME/.agents/skills"
        if [ -d "$local_skills_dir" ]; then
          for skill in "$local_skills_dir"/*; do
            [ -d "$skill" ] || continue
            [ -f "$skill/SKILL.md" ] || continue
            ln -sfn "$skill" "$PI_CODING_AGENT_DIR/skills/$(basename "$skill")"
          done
        fi
      '';
    in
    {
      packages.omp =
        (inputs.agents.packages.${system}.omp.configuration.apply {
          imports = [ baseSettingsModule ];
          config = {
            agents.skills = ompSkills;
            preHook = lib.mkAfter linkLocalSkills;
          };
        }).wrapper;
    };
}
