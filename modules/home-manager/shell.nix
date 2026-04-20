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
            add_newline = true;
            format = "$os$directory$git_branch$git_status\n$character";
            right_format = "$status$cmd_duration$jobs$direnv$python$nodejs$golang$rust$java$kubernetes$terraform$aws$gcloud$nix_shell$time";

            os.disabled = false;

            directory = {
              truncation_length = 3;
              truncate_to_repo = false;
              read_only = " ";
            };

            git_branch.symbol = " ";

            cmd_duration = {
              min_time = 3000;
              show_milliseconds = false;
            };

            jobs.symbol = " ";

            direnv.disabled = false;
            status.disabled = false;
            kubernetes.disabled = true;
            terraform.disabled = false;
            aws.disabled = false;
            gcloud.disabled = false;

            nix_shell = {
              symbol = " ";
              impure_msg = "impure";
              pure_msg = "pure";
              unknown_msg = "";
            };

            time = {
              disabled = false;
              time_format = "%T";
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
