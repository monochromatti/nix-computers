{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      agentPackages = inputs.agents.packages.${system};
    in
    {
      packages.pi =
        (agentPackages.pi.configuration.apply (
          {
            config,
            lib,
            wlib,
            ...
          }:
          let
            jsonFmt = config.pkgs.formats.json { };
            settings = {
              defaultProvider = "azure-openai-responses";
              defaultModel = "gpt-5.4-mini";
              defaultThinkingLevel = "medium";
              subagents.agentOverrides = {
                "context-builder".model = "azure-openai-responses/gpt-5.4";
                planner.model = "azure-openai-responses/gpt-5.4";
                researcher.model = "azure-openai-responses/gpt-5.4";
                reviewer.model = "azure-openai-responses/gpt-5.3-codex";
                scout.model = "azure-openai-responses/gpt-5.4-mini";
                worker.model = "azure-openai-responses/gpt-5.4";
              };
              packages = [
                "npm:pi-subagents"
                "npm:pi-intercom"
                "npm:pi-web-access"
                "npm:pi-boomerang"
                "npm:pi-skill-palette"
                "npm:pi-move-session"
                "npm:pi-prompt-template-model"
                "npm:pi-ghostty"
                "npm:pi-thinking-steps"
                "npm:pi-caveman"
                "npm:pi-mcp-adapter"
                "git:github.com/monochromatti/pi-extensions"
              ];
            };
            mcpServers = {
              linear = {
                url = "https://mcp.linear.app/mcp";
                auth = "oauth";
              };
              chrome-devtools = {
                command = "npx";
                args = [
                  "-y"
                  "chrome-devtools-mcp@latest"
                ];
              };
              playwright = {
                command = "npx";
                args = [
                  "@playwright/mcp@latest"
                  "--headless"
                ];
              };
              svelte = {
                command = "npx";
                args = [
                  "-y"
                  "@sveltejs/mcp"
                ];
              };
            };
          in
          {
            options."mcp.json" = lib.mkOption {
              type = wlib.types.file config.pkgs;
              default.path = jsonFmt.generate "mcp.json" { inherit mcpServers; };
              description = "Generated MCP config copied to ~/.pi/agent/mcp.json.";
            };

            config = {
              inherit settings;

              preHook = lib.mkForce ''
                eval "$(${lib.getExe agentPackages.aienv} --azure)"
                export AZURE_OPENAI_API_KEY="$AZURE_API_KEY"
                export AZURE_OPENAI_RESOURCE_NAME="$AZURE_RESOURCE_NAME"

                # Configure npm to use XDG-compliant directories so Pi extension
                # packages are installed to a user-writable location outside the Nix store.
                npm_prefix="''${XDG_DATA_HOME:-$HOME/.local/share}/npm"
                npm_cache="''${XDG_CACHE_HOME:-$HOME/.cache}/npm"
                npm_userconfig="''${XDG_CONFIG_HOME:-$HOME/.config}/npm/npmrc"

                mkdir -p "$npm_prefix" "$npm_cache" "$(dirname "$npm_userconfig")"
                export NPM_CONFIG_PREFIX="$npm_prefix"
                export NPM_CONFIG_CACHE="$npm_cache"
                export NPM_CONFIG_USERCONFIG="$npm_userconfig"
                export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

                mkdir -p "$HOME/.pi/agent"

                # Merge generated models.json with local overrides.
                models_target="$HOME/.pi/agent/models.json"
                merge_inputs=("${toString config."models.json".path}")

                if [ -f "$models_target" ]; then
                  merge_inputs+=("$models_target")
                fi

                tmp_models="$(mktemp)"
                jq -s 'reduce .[] as $item ({}; . * $item)' "''${merge_inputs[@]}" > "$tmp_models"
                mv "$tmp_models" "$models_target"

                # Keep settings.json Nix-managed.
                settings_target="$HOME/.pi/agent/settings.json"
                cp ${toString config."settings.json".path} "$settings_target"

                # Keep mcp.json Nix-managed. OAuth credentials and metadata caches
                # live separately under ~/.pi/agent and survive rebuilds.
                mcp_target="$HOME/.pi/agent/mcp.json"
                cp ${toString config."mcp.json".path} "$mcp_target"
              '';
            };
          }
        )).wrapper;
    };
}
