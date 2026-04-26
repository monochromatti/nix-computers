{ ... }:
let
  starshipSettings = {
    format = "$username$hostname$directory$git_branch$git_state$git_status$cmd_duration\${custom.nix_develop}$line_break$python$character";
    command_timeout = 2000;

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

  mkDirenvPackage =
    pkgs:
    if pkgs.stdenv.isDarwin then
      pkgs.direnv.overrideAttrs (_: {
        checkPhase = ''
          runHook preCheck
          make test-go test-bash test-zsh
          runHook postCheck
        '';
      })
    else
      pkgs.direnv;

  zshBaseInit = ''
    setopt autocd
    zstyle ':autocomplete:*' list-lines 5

    ${builtins.readFile ../dotfiles/init.zsh}

    eval "$(zoxide init zsh)"

    if [[ $options[zle] = on ]]; then
      source <(fzf --zsh)
    fi
  '';

  commonShell =
    {
      pkgs,
      lib,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        tree
        lazygit
        yazi
        starship
        zoxide
        fzf
      ];

      environment.shellAliases = {
        lg = "lazygit";
        zed = "zeditor .";
        sync-yggdrasil = ''
          gh repo sync && gh repo sync -b dev-base --force && gh repo sync -b dev --force
        '';
      };

      programs.direnv = {
        enable = true;
        package = mkDirenvPackage pkgs;
        nix-direnv.enable = true;
        silent = true;
      };
    };
in
{
  flake.modules.nixos.shell =
    {
      pkgs,
      lib,
      ...
    }:
    {
      imports = [ commonShell ];

      programs.starship = {
        enable = true;
        settings = starshipSettings;
      };

      programs.zsh = {
        enable = true;
        autosuggestions.enable = true;
        syntaxHighlighting.enable = true;
        interactiveShellInit = zshBaseInit;
      };
    };

  flake.modules.darwin.shell =
    {
      pkgs,
      lib,
      ...
    }:
    let
      starshipToml = (pkgs.formats.toml { }).generate "starship.toml" starshipSettings;
    in
    {
      imports = [ commonShell ];

      environment.variables.STARSHIP_CONFIG = "/etc/starship.toml";
      environment.etc."starship.toml".source = starshipToml;

      programs.zsh = {
        enable = true;
        enableAutosuggestions = true;
        enableSyntaxHighlighting = true;
        interactiveShellInit = zshBaseInit;
        promptInit = ''
          if [[ $TERM != "dumb" ]]; then
            eval "$(starship init zsh)"
          fi
        '';
      };
    };
}
