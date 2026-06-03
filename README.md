# nix-computers

Personal computer configuration using Nix.

Tries to adhere to [dendritic Nix](https://github.com/Doc-Steve/dendritic-design-with-flake-parts) design patterns, as it keeps things modular and leverages the flake-parts module system well. Also aims to keep features separately defined from hosts, for easy reuse across hosts (nixos and darwin).

## My stack

Two main hosts: **firefly** (NixOS work laptop) and **macarius** (nix-darwin / macOS). They share a terminal, shell, and editor stack; the desktop and GUI app layers differ per platform.

### Shared (firefly + macarius)

#### Terminal
- [ghostty](https://ghostty.org/) — terminal emulator
- [zsh](https://www.zsh.org/) — shell (with autosuggestions + syntax highlighting)
- [starship](https://starship.rs/) — prompt
- [yazi](https://yazi-rs.github.io/) — file browsing
- [zoxide](https://github.com/ajeetdsouza/zoxide) — smart `cd`
- [fzf](https://github.com/junegunn/fzf) — fuzzy finder
- [eza](https://github.com/eza-community/eza) — `ls` replacement
- [ripgrep](https://github.com/BurntSushi/ripgrep) / [fd](https://github.com/sharkdp/fd) — search
- [jq](https://jqlang.github.io/jq/) — JSON wrangling
- [lazygit](https://github.com/jesseduffield/lazygit) — git TUI
- [direnv](https://direnv.net/) — per-directory environments (with [nix-direnv](https://github.com/nix-community/nix-direnv))

#### Editor
- [zed](https://zed.dev/) — primary editor (Nord theme, vim mode, direnv-aware)

#### Development
- Nix: [nixd](https://github.com/nix-community/nixd), [nixfmt](https://github.com/NixOS/nixfmt), [nil](https://github.com/oxalica/nil)
- Python: [uv](https://github.com/astral-sh/uv), [ruff](https://github.com/astral-sh/ruff), [ty](https://github.com/astral-sh/ty)
- Rust: [rust-analyzer](https://rust-analyzer.github.io/), cargo
- JS: [Node.js](https://nodejs.org/)
- [devenv](https://devenv.sh/) — developer environments
- [git](https://git-scm.com/) + [gh](https://cli.github.com/) — version control
- [docker](https://www.docker.com/) / docker-compose — containers
- [azure-cli](https://learn.microsoft.com/en-us/cli/azure/) — cloud

#### AI
- [pi](https://github.com/numtide/llm-agents.nix) — coding agent (via [llm-agents.nix](https://github.com/numtide/llm-agents.nix) / [agents](https://github.com/fornybar/agents))

#### Publishing & documents
- [quarto](https://quarto.org/) — scientific/technical publishing
- [TeX Live](https://www.tug.org/texlive/) — LaTeX
- [pandoc](https://pandoc.org/) — document conversion
- [glow](https://github.com/charmbracelet/glow) — markdown in the terminal
- [d2](https://d2lang.com/) — diagrams
- [silicon](https://github.com/Aloxaf/silicon) — code screenshots

## Firefly (NixOS)

Work laptop (HP ZBook Firefly G11). Login via [greetd](https://git.sr.ht/~kennylevinsen/greetd) + [tuigreet](https://github.com/apognu/tuigreet).

### Desktop
- [niri](https://github.com/YaLTeR/niri) — scrollable-tiling Wayland window manager
- [noctalia-shell](https://github.com/noctalia-dev/noctalia-shell) — Wayland shell / bar (Quickshell-based)
- [vicinae](https://docs.vicinae.com/) — application launcher
- [overskride](https://github.com/kaii-lb/overskride) — Bluetooth manager
- [daily-hours](https://github.com/monochromatti/daily-hours) — work-time tracking (integrated into the bar)
- Theming: [adw-gtk3](https://github.com/lassekongo83/adw-gtk3), [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme), [qt6ct](https://github.com/trialuser02/qt6ct), Inter + JetBrains Mono fonts

### Apps
- [obsidian](https://obsidian.md/) — notes
- [spotify](https://www.spotify.com/) — music
- [okular](https://okular.kde.org/) — PDF viewer
- [LibreOffice](https://www.libreoffice.org/) — office suite
- [bitwarden](https://bitwarden.com/) — passwords
- [inkscape](https://inkscape.org/) / [GIMP](https://www.gimp.org/) — graphics
- [keymapp](https://www.zsa.io/flash) — ZSA keyboard config
- [NATS](https://nats.io/) CLI (`natscli`, `nsc`)

## Macarius (nix-darwin)

macOS (Apple Silicon). Linux dev environment provided through a [Lima](https://lima-vm.io/) VM ([nixos-lima](https://github.com/nixos-lima/nixos-lima)). GUI apps are installed via [Homebrew](https://brew.sh/) casks.

### Apps
- [Raycast](https://www.raycast.com/) — launcher
- [Visual Studio Code](https://code.visualstudio.com/)
- [Obsidian](https://obsidian.md/) — notes
- [Zotero](https://www.zotero.org/) — references
- [Affinity](https://affinity.serif.com/) Designer / Photo / Publisher — design
- [Spotify](https://www.spotify.com/) — music
- [Discord](https://discord.com/), [Zoom](https://zoom.us/) — communication
- [VLC](https://www.videolan.org/), [Transmission](https://transmissionbt.com/) — media
- [Keka](https://www.keka.io/) — archiving
- [SoundSource](https://rogueamoeba.com/soundsource/), [Loop](https://github.com/MrKai77/Loop)
