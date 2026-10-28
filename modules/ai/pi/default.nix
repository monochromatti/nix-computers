{ inputs, self, ... }:
{
  flake.modules.hjem."feature/ai" =
    { config, lib, ... }:
    lib.mkIf (lib.elem "ai" config.nixComputers.profileFeatures) {
      files = {
        ".pi/agent/subagent-manager/settings.json" = {
          type = "copy";
          source = ./subagent-settings.json;
          clobber = false;
        };
        ".pi/agent/web-search.json" = {
          text = builtins.toJSON {
            provider = "azure";
            model = "gpt-6-luna";
          };
          clobber = true;
        };
      }
      //
        lib.mapAttrs
          (_: source: {
            inherit source;
            clobber = true;
          })
          {
            ".pi/agent/SYSTEM.md" = ./SYSTEM.md;
            ".pi/agent/keybindings.json" = ./keybindings.json;
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

      anatomySkillSource = pkgs.fetchFromGitHub {
        owner = "wheresryan22";
        repo = "anatomy";
        rev = "dbf697a527bbf7d358668e1557cb1e35ff725d46";
        hash = "sha256-YrftHzMQPHrHY/iVnWXGxst+PRwu+PDTqgpZAHhkzDo=";
      };

      typedbSkillsSource = pkgs.fetchFromGitHub {
        owner = "typedb";
        repo = "typedb-skills";
        rev = "fc20bccf7b279600170e33d9de85901b5983ed0b";
        hash = "sha256-DKyKI1OeCC55bJxLBwae5sg2ngtfabjIaNp80Syl3kw=";
      };

      showMeSkill = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/humanlayer/skills/653b6411c1f70c275a18e37673b042ff99f67ceb/plugins/show-me/skills/show-me/SKILL.md";
        hash = "sha256-Q0ojRsyV4xOw02fUd92i4jumQt0hgXV0FaCVAGZK8QA=";
      };

      enabledFornybarSkills = [
        "ast-grep"
        "atomic-history"
        "create-plan"
        "create-spec"
        "good-code"
        "microsoft-decision"
        "teach-me"
      ];

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
              "chrome-devtools"
            ];
            registry.playwright = {
              transport = "stdio";
              command = lib.getExe pkgs.playwright-mcp;
              args = [ "--isolated" ];
            };
            registry.chrome-devtools = {
              transport = "stdio";
              command = "npx";
              args = [
                "-y"
                "chrome-devtools-mcp@latest"
                "--browserUrl"
                "http://127.0.0.1:9222"
              ];
            };
          };

          agents.skillSources = [
            "${anatomySkillSource}"
            "${self}/.agents/skills"
            ./skills
          ];
          agents.skills = lib.genAttrs enabledFornybarSkills (_: {
            enable = true;
          });

          settings = {
            defaultProvider = "azure";
            defaultModel = "gpt-6-luna";
            defaultThinkingLevel = "high";
          };
        };
      };

      skills = [
        "${typedbSkills}/typedb-modeling.md"
        "${typedbSkills}/typedb-typeql.md"
        "${showMeSkill}"
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
        skills = [ ];
      };

    in
    {
      options.pi.extensions = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };

      config.apps.chrome-devtools = {
        type = "app";
        program = lib.getExe (
          pkgs.writeShellScriptBin "chrome-devtools" ''
            exec ${
              if pkgs.stdenv.isDarwin then
                "\"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome\""
              else
                "google-chrome"
            } \
              --remote-debugging-address=127.0.0.1 \
              --remote-debugging-port=9222 \
              --user-data-dir="$HOME/.config/chrome-for-devtools" "$@"
          ''
        );
        meta.description = "Start Chrome for the Pi Chrome DevTools MCP";
      };

      config.packages.pi = mkPi {
        imports = [ baseSettingsModule ];
        config = {
          binName = "pi";
          env.PI_OFFLINE = "1";
          settings = {
            inherit skills;
            packages = map (source: { source = toString source; }) config.pi.extensions ++ [
              piExtensionsPackage
              piAgentsPackage
            ];
          };
        };
      };

    };
}
