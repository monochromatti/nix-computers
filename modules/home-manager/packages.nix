{ inputs, self, ... }:
let
  piModels = ../../packages/pi/config/models.json;

  commonPackages =
    {
      pkgs,
      lib,
      ...
    }:
    let
      latex = pkgs.texliveMedium.withPackages (ps: with ps; [ arara ]);
      daily-hours = self.packages.${pkgs.stdenv.hostPlatform.system}.daily-hours;
      pi = self.packages.${pkgs.stdenv.hostPlatform.system}.pi;
      upkgs = import inputs.nixpkgs-unstable {
        system = pkgs.stdenv.hostPlatform.system;
      };
    in
    {
      home.packages = [
        daily-hours
        pi

        # Nix
        pkgs.nixfmt-rfc-style
        pkgs.nixpkgs-fmt
        pkgs.nixd

        # Rust
        pkgs.rust-analyzer
        pkgs.cargo

        # Python
        upkgs.uv
        upkgs.ty
        upkgs.ruff

        # JavaScript
        upkgs.nodejs_24

        # Graphics
        pkgs.d2
        pkgs.silicon

        # Dev
        pkgs.gh
        pkgs.git
        pkgs.docker
        pkgs.azure-cli
        pkgs.qemu

        # Shell
        pkgs.eza
        pkgs.ripgrep

        # Docs
        pkgs.pandoc
        pkgs.quarto
        latex
      ];

      home.activation.piModels = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        models_dir="$HOME/.pi/agent"
        models_target="$models_dir/models.json"

        ${pkgs.coreutils}/bin/mkdir -p "$models_dir"

        tmp_models="$(${pkgs.coreutils}/bin/mktemp)"
        if [ -f "$models_target" ]; then
          ${lib.getExe pkgs.jq} -s 'reduce .[] as $item ({}; . * $item)' \
            "${piModels}" "$models_target" > "$tmp_models"
        else
          ${lib.getExe pkgs.jq} -s 'reduce .[] as $item ({}; . * $item)' \
            "${piModels}" > "$tmp_models"
        fi

        ${pkgs.coreutils}/bin/mv "$tmp_models" "$models_target"
      '';
    };

  linuxPackages =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        # Terminal
        ghostty
        xclip

        # UI programs
        spotify
        bitwarden-desktop
        kdePackages.okular
        libreoffice
        keymapp

        # Text editors
        obsidian

        # Graphics
        inkscape
        gimp

        # Docker
        docker-compose

        # NATS
        natscli
        nsc

        # Other
        gpu-screen-recorder
      ];
    };
in
{
  flake.modules.homeManager.packages = commonPackages;

  flake.modules.nixos.packages = {
    home-manager.sharedModules = [ linuxPackages ];
  };
}
