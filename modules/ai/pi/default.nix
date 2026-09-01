{ inputs, self, ... }:
{
  flake.modules.hjem."feature/ai" =
    { config, lib, ... }:
    lib.mkIf (lib.elem "ai" config.nixComputers.profileFeatures) {
      files.".pi/agent/SYSTEM.md" = {
        source = ./SYSTEM.md;
        clobber = true;
      };
    };

  perSystem =
    { pkgs, lib, ... }:
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

      baseSettingsModule = {
        config = {
          agents.skillSources = [ "${herdrSkillSource}/skills/herdr" ];

          mcp = {
            package = "${extensionPackages.pi-mcp-adapter}";
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

      extensionPackages = {
        pi-herdr-subagents = import ./extensions/pi-herdr-subagents.nix { inherit pkgs lib; };
        pi-impeccable = import ./extensions/pi-impeccable.nix { inherit pkgs lib; };
        pi-mcp-adapter = import ./extensions/pi-mcp-adapter.nix { inherit pkgs lib; };
        pi-pretty = import ./extensions/pi-pretty.nix { inherit pkgs lib; };
        pi-prompt-template-model = import ./extensions/pi-prompt-template-model.nix { inherit pkgs lib; };
        pi-web-access = import ./extensions/pi-web-access.nix { inherit pkgs lib; };
      };

      extensions = [
        "npm:pi-ghostty"
      ]
      ++ lib.mapAttrsToList (_: package: {
        source = "${package}";
      }) (removeAttrs extensionPackages [ "pi-mcp-adapter" ]);

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

      piAgentsPackage = {
        source = "${./.}";
      };

    in
    {
      packages.pi = mkPi {
        imports = [ baseSettingsModule ];
        config = {
          binName = "pi";
          env.PI_OFFLINE = "1";
          settings = {
            inherit skills;
            packages = extensions ++ [
              piExtensionsPackage
              piAgentsPackage
            ];
          };
        };
      };

    };
}
