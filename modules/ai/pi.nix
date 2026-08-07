{ inputs, self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;

      mkPi =
        module:
        (inputs.agents.packages.${system}.pi.configuration.apply {
          imports = [ module ];
        }).wrapper;

      baseSettingsModule = {
        config = {
          mcp = {
            enabled = [
              "linear"
              "playwright"
              "remarkable"
              "chrome-devtools"
            ];
            registry.chrome-devtools = {
              transport = "stdio";
              command = "npx";
              args = [ "chrome-devtools-mcp@latest" ];
            };
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
            subagents.agentOverrides = {
              oracle = {
                model = "azure-openai-responses/gpt-5.6-sol";
                thinking = "medium";
              };
              worker = {
                model = "azure-openai-responses/gpt-5.6-luna";
                thinking = "medium";
              };
              scout = {
                model = "azure-openai-responses/gpt-5.6-terra";
                thinking = "low";
              };
              planner = {
                model = "azure-openai-responses/gpt-5.6-sol";
                thinking = "low";
              };
            };
          };
        };
      };

      extensions = [
        "npm:pi-web-access"
        "npm:pi-prompt-template-model"
        "npm:pi-ghostty"
        "npm:pi-thinking-steps"
        "npm:pi-caveman"
        "npm:pi-mcp-adapter"
        "npm:pi-impeccable"
        "npm:pi-subagents"
        "npm:@heyhuynhgiabuu/pi-pretty"
      ];

      skills = [
        "~/.agents/skills"
        "${inputs.agents}/.agents/skills"
        "${self}/.agents/skills"
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

    in
    {
      packages.pi = mkPi {
        imports = [ baseSettingsModule ];
        config = {
          binName = "pi";
          settings = {
            inherit skills;
            packages = extensions ++ [ piExtensionsPackage ];
          };
        };
      };

      packages.pi-dev = mkPi {
        imports = [ baseSettingsModule ];
        config = {
          binName = "pi-dev";
          filesToExclude = [ "bin/pi" ];
          settings = {
            inherit skills extensions;
          };
        };
      };
    };
}
