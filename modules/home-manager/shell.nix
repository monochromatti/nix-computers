{ ... }:
{
  flake.modules.homeManager.shell =
    { pkgs, ... }:
    {

      home.packages = with pkgs; [
        tree
        lazygit
        yazi
      ];

      programs = {
        home-manager.enable = true;

        starship = {
          enable = true;
          enableZshIntegration = true;
          settings = {
            format = "$username$hostname$directory$git_branch$git_state$git_status$cmd_duration\${custom.nix_develop}$line_break$python$character";

            directory.style = "blue";

            character = {
              success_symbol = "[❯](purple)";
              error_symbol = "[❯](red)";
              vimcmd_symbol = "[❮](green)";
            };

            git_branch = {
              format = "[$branch]($style)";
              style = "bright-black";
            };

            git_status = {
              format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)";
              style = "cyan";
              conflicted = "​";
              untracked = "​";
              modified = "​";
              staged = "​";
              renamed = "​";
              deleted = "​";
              stashed = "≡";
            };

            git_state = {
              format = "\\([$state( $progress_current/$progress_total)]($style)\\) ";
              style = "bright-black";
            };

            cmd_duration = {
              format = "[$duration]($style) ";
              style = "yellow";
            };

            python = {
              format = "[$virtualenv]($style) ";
              style = "bright-black";
              detect_extensions = [ ];
              detect_files = [ ];
            };

            custom.nix_develop = {
              description = "Shown only when inside an actual nix develop shell";
              when = ''
                [ -n "$IN_NIX_SHELL" ] &&
                [ -n "$NIX_BUILD_TOP" ]
              '';
              command = "true";
              format = "[❄️]($style) ";
              style = "blue";
            };
          };
        };

        zoxide = {
          enable = true;
          enableZshIntegration = true;
        };

        direnv = {
          enable = true;
          enableZshIntegration = true;
          nix-direnv.enable = true;
          silent = true;
        };

        dircolors.enable = true;
        fzf.enable = true;

        zsh = {
          enable = true;
          autocd = true;
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;
          envExtra = ''
            zstyle ':autocomplete:*' list-lines 5
          '';
          initContent = ''
            source ${../../dotfiles/init.zsh}
          '';
        };
      };
    };
}
