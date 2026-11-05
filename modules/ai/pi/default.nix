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

      mkPi =
        module:
        (inputs.agents.packages.${system}.pi.configuration.apply {
          imports = [ module ];
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
            ./skills
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
        { config, ... }:
        {
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
            subagents.agentOverrides =
              lib.genAttrs
                [
                  "scout"
                  "planner"
                  "oracle"
                  "engineer"
                  "visual-scout"
                  "verifier"
                  "worker"
                  "deep-reviewer"
                  "researcher"
                  "fast-reviewer"
                ]
                (_: {
                  model = "inherit";
                });
          };
          preHook = lib.mkForce ''
            unset AZURE_API_KEY AZURE_OPENAI_API_KEY AZURE_OPENAI_BASE_URL AZURE_OPENAI_RESOURCE_NAME
            export PI_CODING_AGENT_DIR="$HOME/.pi-home/agent"
            if [ "$(id -u)" -eq 0 ]; then
              echo "pi-home must not run as root" >&2
              exit 1
            fi
            npm_prefix="''${XDG_DATA_HOME:-$HOME/.local/share}/npm"
            npm_cache="''${XDG_CACHE_HOME:-$HOME/.cache}/npm"
            npm_userconfig="''${XDG_CONFIG_HOME:-$HOME/.config}/npm/npmrc"
            mkdir -p "$npm_prefix" "$npm_cache" "$(dirname "$npm_userconfig")" "$PI_CODING_AGENT_DIR"
            export NPM_CONFIG_PREFIX="$npm_prefix" NPM_CONFIG_CACHE="$npm_cache" NPM_CONFIG_USERCONFIG="$npm_userconfig"
            export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
            install -m 644 ${toString config."models.json".path} "$PI_CODING_AGENT_DIR/models.json"
            install -m 644 ${toString config."settings.json".path} "$PI_CODING_AGENT_DIR/settings.json"
            install -m 644 ${toString config."mcp.json".path} "$PI_CODING_AGENT_DIR/mcp.json"
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
