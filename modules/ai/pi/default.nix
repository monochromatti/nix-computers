{ inputs, self, ... }:
{
  flake.modules.hjem."feature/ai" =
    { config, lib, ... }:
    lib.mkIf (lib.elem "ai" config.nixComputers.profileFeatures) {
      files =
        lib.mapAttrs
          (_: source: {
            inherit source;
            clobber = true;
          })
          {
            ".pi/agent/SYSTEM.md" = ./SYSTEM.md;
            ".pi/agent/keybindings.json" = ./keybindings.json;
            ".pi/agent/agents/deep-reviewer.md" = ./agents/deep-reviewer.md;
            ".pi/agent/agents/engineer.md" = ./agents/engineer.md;
            ".pi/agent/agents/fast-reviewer.md" = ./agents/fast-reviewer.md;
            ".pi/agent/agents/oracle.md" = ./agents/oracle.md;
            ".pi/agent/agents/planner.md" = ./agents/planner.md;
            ".pi/agent/agents/researcher.md" = ./agents/researcher.md;
            ".pi/agent/agents/scout.md" = ./agents/scout.md;
            ".pi/agent/agents/verifier.md" = ./agents/verifier.md;
            ".pi/agent/agents/worker.md" = ./agents/worker.md;
          };
    };

  perSystem =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;

      mkPi =
        module:
        (inputs.agents.packages.${system}.pi.configuration.apply {
          imports = [ module ];
        }).wrapper;

      herdrSkillSource = pkgs.fetchFromGitHub {
        owner = "herdrdev";
        repo = "herdr";
        rev = "346411fa21afd297f5ed3b3fa56f9e3fbf7654b7";
        hash = "sha256-empFQ+hrnCh2JhOzQRWSCLV0YoZC3DXW3bY6k8YuJjk=";
      };

      typedbSkillsSource = pkgs.fetchFromGitHub {
        owner = "typedb";
        repo = "typedb-skills";
        rev = "fc20bccf7b279600170e33d9de85901b5983ed0b";
        hash = "sha256-DKyKI1OeCC55bJxLBwae5sg2ngtfabjIaNp80Syl3kw=";
      };

      typedbSkills = pkgs.linkFarm "typedb-skills" [
        {
          name = "typedb-modeling.md";
          path = "${typedbSkillsSource}/modeling.md";
        }
        {
          name = "typedb-typeql.md";
          path = "${typedbSkillsSource}/typeql.md";
        }
      ];

      baseSettingsModule = {
        config = {
          mcp = {
            enabled = [
              "grafana-prod"
              "linear"
              "azure"
              "playwright"
            ];
            registry.playwright = {
              transport = "stdio";
              command = lib.getExe pkgs.playwright-mcp;
              args = [
                "--headless"
                "--isolated"
              ];
            };
          };

          agents.skillSources = [
            "${herdrSkillSource}/skills/herdr"
            ./skills
          ];

          settings = {
            defaultProvider = "azure-openai-responses";
            defaultModel = "gpt-6-luna";
            defaultThinkingLevel = "high";
          };
        };
      };

      skills = [
        "~/.agents/skills"
        "${inputs.agents}/.agents/skills"
        "${self}/.agents/skills"
        "${typedbSkills}/typedb-modeling.md"
        "${typedbSkills}/typedb-typeql.md"
      ];

      piExtensionsPackage = {
        source = "git:github.com/monochromatti/pi-extensions";
        extensions = [
          "packages/pi-tree-map/index.ts"
          "packages/pi-answer/index.ts"
          "packages/pi-zed-context/index.ts"
          "packages/pi-canvas/index.ts"
        ];
        skills = [
          "packages/pi-zed-context/skills/**"
          "packages/pi-canvas/skills/**"
        ];
      };

      piAgentsPackage = {
        source = "${./.}";
      };

    in
    {
      options.pi.extensions = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };

      config.packages.pi = mkPi {
        imports = [ baseSettingsModule ];
        config = {
          binName = "pi";
          env.PI_OFFLINE = "1";
          settings = {
            inherit skills;
            packages = map (source: { source = toString source; }) config.pi.extensions ++ [
              "npm:pi-ghostty"
              piExtensionsPackage
              piAgentsPackage
            ];
          };
        };
      };

    };
}
