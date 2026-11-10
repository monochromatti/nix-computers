{ inputs, self, ... }:
{
  flake.modules.hjem."feature/ai" =
    { lib, ... }:
    {
      files = {
        ".pi/agent/extensions/subagent/config.json" = {
          text = builtins.toJSON {
            maxSubagentDepth = 1;
            defaultSubagentContext = "fresh";
          };
          clobber = true;
        };
        ".pi-home/agent/extensions/subagent/config.json" = {
          text = builtins.toJSON {
            maxSubagentDepth = 1;
            defaultSubagentContext = "fresh";
          };
          clobber = true;
        };
        ".pi/agent/web-search.json" = {
          text = builtins.toJSON {
            provider = "azure";
            model = "gpt-6-luna";
          };
          clobber = true;
        };
        ".pi-home/agent/web-search.json" = {
          text = builtins.toJSON {
            provider = "opencode-go";
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
            ".pi/agent/APPEND_SYSTEM.md" = ./APPEND_SYSTEM.md;
            ".pi/agent/keybindings.json" = ./keybindings.json;
            ".pi-home/agent/SYSTEM.md" = ./SYSTEM.md;
            ".pi-home/agent/APPEND_SYSTEM.md" = ./APPEND_SYSTEM.md;
            ".pi-home/agent/keybindings.json" = ./keybindings.json;
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

      manualOnly =
        src: pattern:
        pkgs.runCommand (src.name or "manual-only") { } ''
          cp -rL --no-preserve=mode ${src} $out
          find $out -type f -path "${pattern}" -exec sed -i "0,/^---$/s//---\ndisable-model-invocation: true/" {} +
        '';

      agentsPi = inputs.agents.packages.${system}.pi.configuration;
      oldSubagents = inputs.agents.packages.${system}.pi-subagents;
      subagents = pkgs.buildNpmPackage {
        pname = "pi-subagents";
        version = "0.87.0";
        src = pkgs.fetchFromGitHub {
          owner = "nicobailon";
          repo = "pi-subagents";
          rev = "52e68e9ef0e563d5c97b28519f9999f1b5fbbbea";
          hash = "sha256-jjumBpE2OrUmeut7M3wZDlLjEA9mbA7Q21NepUYHU5s=";
        };
        npmDepsHash = "sha256-aGw6EkTn6zIf29rx69B/6lEjHjxF6ZZCHbslXhy4ITg=";
        npmBuildScript = "build:pkg";
        installPhase = ''
          runHook preInstall
          npm prune --omit=dev --ignore-scripts --offline
          mkdir -p "$out"
          cp -r dist-pkg/. "$out/"
          cp -r node_modules "$out/"
          runHook postInstall
        '';
      };

      mkPi =
        module:
        let
          original = agentsPi.apply { imports = [ module ]; };
          replaceSubagents = lib.replaceStrings [ (toString oldSubagents) ] [ (toString subagents) ];
        in
        (agentsPi.apply {
          imports = [
            module
            {
              bundledExtensions = lib.mkForce (map replaceSubagents original.bundledExtensions);
              settings.skills = lib.mkForce (map replaceSubagents original.settings.skills);
              settings.prompts = lib.mkForce (map replaceSubagents original.settings.prompts);
            }
          ];
        }).wrapper;

      anatomySkillSource = manualOnly (pkgs.fetchFromGitHub {
        owner = "wheresryan22";
        repo = "anatomy";
        rev = "dbf697a527bbf7d358668e1557cb1e35ff725d46";
        hash = "sha256-YrftHzMQPHrHY/iVnWXGxst+PRwu+PDTqgpZAHhkzDo=";
      }) "*/SKILL.md";

      typedbSkillsSource = pkgs.fetchFromGitHub {
        owner = "typedb";
        repo = "typedb-skills";
        rev = "fc20bccf7b279600170e33d9de85901b5983ed0b";
        hash = "sha256-DKyKI1OeCC55bJxLBwae5sg2ngtfabjIaNp80Syl3kw=";
      };

      showMeSkill = manualOnly (pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/humanlayer/skills/653b6411c1f70c275a18e37673b042ff99f67ceb/plugins/show-me/skills/show-me/SKILL.md";
        hash = "sha256-Q0ojRsyV4xOw02fUd92i4jumQt0hgXV0FaCVAGZK8QA=";
      }) "*";

      enabledFornybarSkills = [
        "ast-grep"
        "atomic-history"
        "create-plan"
        "create-spec"
        "good-code"
        "microsoft-decision"
        "teach-me"
      ];

      typedbSkills = manualOnly (pkgs.linkFarm "typedb-skills" [
        {
          name = "typedb-modeling.md";
          path = "${typedbSkillsSource}/modeling.md";
        }
        {
          name = "typedb-typeql.md";
          path = "${typedbSkillsSource}/typeql.md";
        }
      ]) "*.md";

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
          ];
          agents.skills = lib.genAttrs enabledFornybarSkills (_: {
            enable = true;
          });

          settings = {
            defaultProvider = "azure";
            defaultModel = "gpt-6.1-terra";
            defaultThinkingLevel = "medium";
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
        ];
        skills = [
          "packages/pi-zed-context/skills/**"
        ];
      };

      piAgentsPackage = {
        source = "${./.}";
        skills = [ ];
      };

      piPackages = map (source: { source = toString source; }) config.pi.extensions ++ [
        piExtensionsPackage
        piAgentsPackage
      ];
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

      config.packages.pi-home = mkPi (
        { ... }:
        {
          imports = [
            {
              preHook = lib.mkBefore ''
                export PI_CODING_AGENT_DIR="$HOME/.pi-home/agent"
              '';
            }
          ];
          binName = "pi-home";
          filesToExclude = [ "bin/pi" ];
          models.providers = lib.mkForce {
            opencode-go.apiKey = "!cat /run/secrets/opencode-api-key";
          };
          mcp.enabled = lib.mkForce [ ];
          agents.skills = lib.mkForce { };
          settings = {
            defaultProvider = "opencode-go";
            defaultModel = "deepseek-v4.1-flash";
            defaultThinkingLevel = "medium";
            enabledModels = [
              "opencode-go/deepseek-v4.1-flash"
              "opencode-go/*"
            ];
            inherit skills;
            packages = piPackages;
            subagents.modelScope = {
              enforce = true;
              strict = true;
              allow = [ "opencode-go/*" ];
            };
          };
          preHook = lib.mkOrder 700 ''
            unset AZURE_API_KEY AZURE_OPENAI_API_KEY AZURE_OPENAI_BASE_URL AZURE_OPENAI_RESOURCE_NAME
          '';
        }
      );

      config.packages.pi = mkPi {
        imports = [ baseSettingsModule ];
        config = {
          binName = "pi";
          settings = {
            inherit skills;
            packages = piPackages;
          };
        };
      };

    };
}
