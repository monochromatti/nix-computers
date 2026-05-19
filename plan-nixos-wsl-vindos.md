# Implementation plan for nixos-wsl-vindos

Goal: add a manual-install NixOS-WSL host named `vindos` to this flake. It should behave like a minimal terminal-only version of `firefly`: same comfortable shell/dev feel where safe, no GUI/desktop/hardware baggage. Default WSL user must be `monochromatti`.

This repo uses `flake-parts` plus `import-tree`, with reusable modules under `modules/`. Treat the flake outputs as the public interface. Prefer behavior checks that evaluate `.#nixosConfigurations.vindos.config...` over tests coupled to file layout.

## Relevant files

- `spec-nixos-wsl-vindos.md` - Source specification for this plan.
- `flake.nix` - Add `nixos-wsl` input.
- `modules/hosts/vindos/default.nix` - New host module exposing `nixosConfigurations.vindos` and WSL config.
- `modules/hosts/vindos/checks.nix` - Optional host-specific flake checks for public `vindos` config behavior.
- `modules/users/monochromatti/default.nix` - Existing user/Home Manager wiring; may need WSL-safe split or extra module.
- `modules/home-manager/packages.nix` - Existing package module mixes CLI/dev and GUI packages; likely source of WSL profile split.
- `modules/home-manager/linux.nix` - GUI/desktop-heavy Linux Home Manager module; should not be imported by WSL profile.
- `modules/nixos/base.nix` - Shared NixOS base; verify WSL compatibility before reuse.
- `modules/shell/shell.nix` - Shared shell module to reuse for `zsh`, aliases, direnv, starship.
- `modules/shell/starship.nix` - Starship prompt settings expected in `vindos`.
- `modules/shell/zsh.nix` - Zsh settings expected in `vindos`.
- `modules/lib.nix` - Existing `mkNixos` helper used by hosts.

## Instructions for completing tasks

Before starting work, check current state of tasks (find out what has already been completed), and read Notes section.

**IMPORTANT:** As you complete each task, check it off in this markdown file by changing `- [ ]` to `- [x]`. This helps track progress and ensures you don't skip any steps.

Example:
- `- [ ] 1.1 Read file` → `- [x] 1.1 Read file` (after completing)

Update file after completing each sub-task, not only after completing entire parent task.

If applicable, update Notes section with lessons, discoveries, and design choices useful for next engineer.

## Tasks

- [x] 1.0 Add public `vindos` NixOS configuration shell
  - [x] 1.1 RED: Add one failing behavior check that expects public output `.#nixosConfigurations.vindos` to evaluate.
    - Suggested command first: `nix eval .#nixosConfigurations.vindos.config.networking.hostName` should fail before implementation.
    - If adding persistent checks, create `modules/hosts/vindos/checks.nix` with a flake check that references the public `vindos` configuration and fails while missing.
  - [x] 1.2 GREEN: Add `nixos-wsl` input to `flake.nix` and create `modules/hosts/vindos/default.nix` exposing `flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "vindos";`.
  - [x] 1.3 GREEN: Add minimal `flake.modules.nixos.vindos` with enough config to evaluate: host platform via existing helper, `networking.hostName = "vindos"`, and temporary/minimal `system.stateVersion`.
  - [x] 1.4 REFACTOR: Keep host file small and aligned with `modules/hosts/firefly/default.nix` style. Remove any temporary config no longer needed.

- [x] 2.0 Enable NixOS-WSL behavior for `vindos`
  - [x] 2.1 RED: Add one behavior check/eval for WSL basics:
    - `nix eval .#nixosConfigurations.vindos.config.wsl.enable` should become `true`.
    - `nix eval .#nixosConfigurations.vindos.config.wsl.defaultUser` should become `"monochromatti"`.
  - [x] 2.2 GREEN: Import `inputs.nixos-wsl.nixosModules.default` in `modules/hosts/vindos/default.nix` and configure:
    - `wsl.enable = true;`
    - `wsl.defaultUser = "monochromatti";`
  - [x] 2.3 RED: Add one behavior check/eval for Nix flakes support:
    - `nix eval --json .#nixosConfigurations.vindos.config.nix.settings.experimental-features` should include `nix-command` and `flakes`.
  - [x] 2.4 GREEN: Configure `nix.settings.experimental-features = [ "nix-command" "flakes" ];` in `vindos` or shared base if appropriate.
  - [x] 2.5 REFACTOR: Ensure NixOS-WSL input follows compatible nixpkgs source. If following repo `nixpkgs` breaks eval, document and switch to NixOS-WSL recommended input behavior.

- [x] 3.0 Build terminal-only Firefly-like shell environment
  - [x] 3.1 RED: Add one behavior check/eval for shell comfort:
    - `programs.zsh.enable == true`
    - `programs.starship.enable == true`
    - `programs.direnv.enable == true`
  - [x] 3.2 GREEN: Import safe shared modules in `vindos`, likely `base` and `shell`, then make minimal adjustments until check passes.
  - [x] 3.3 RED: Add one behavior check/eval that required CLI tools are present in system packages or user profile.
    - Minimum set: `git`, `gh`, `ripgrep`, `eza` or equivalent, `fzf`, `zoxide`, `lazygit`, Nix formatter/LSP if expected.
    - Test through evaluated package names/derivations, not through implementation-specific import paths.
  - [x] 3.4 GREEN: Add missing terminal/dev packages via smallest safe module change.
    - Prefer reusing existing CLI package modules.
    - If existing module pulls GUI packages, create WSL-safe package split instead of importing it wholesale.
  - [x] 3.5 REFACTOR: Remove duplicate package declarations and keep shell packages in existing `modules/shell/*` when broadly useful.

- [x] 4.0 Wire `monochromatti` user with WSL-safe Home Manager profile
  - [x] 4.1 RED: Add one behavior check/eval for user presence and defaults:
    - `users.users.monochromatti.isNormalUser == true` or equivalent existing user convention.
    - home directory resolves to `/home/monochromatti`.
    - shell resolves to zsh where expected.
  - [x] 4.2 GREEN: Configure `monochromatti` user through existing `midgard.pc.users` convention and/or NixOS `users.users` as required by current modules.
  - [x] 4.3 RED: Add one behavior check/eval that Home Manager is wired for `monochromatti` without importing GUI-heavy modules.
    - It should evaluate `home-manager.users.monochromatti` successfully.
    - It should not include known GUI-heavy packages/services from the full Linux desktop profile.
  - [x] 4.4 GREEN: Implement minimal WSL-safe Home Manager wiring.
    - Option A: add `flake.modules.homeManager.monochromatti-wsl` and a matching NixOS module for WSL.
    - Option B: split existing `modules/home-manager/packages.nix` into CLI/dev and GUI pieces, then import only CLI/dev for WSL.
    - Choose smallest maintainable diff.
  - [x] 4.5 REFACTOR: Ensure existing `firefly` behavior remains unchanged after any package/profile split.

- [x] 5.0 Prove GUI/desktop/hardware modules are absent
  - [x] 5.1 RED: Add one behavior check/eval that fails if `vindos` includes known GUI/desktop packages or services.
    - Examples to exclude: `spotify`, `obsidian`, `libreoffice`, `gimp`, `inkscape`, `bitwarden-desktop`, Noctalia/Vicinae user services, Niri-related modules.
  - [x] 5.2 GREEN: Remove or avoid imports that pull desktop/hardware/GUI closure into `vindos`.
    - Do not import `niri`, `desktop`, `hardware`, Firefly hardware, PC laptop modules, Noctalia, or Vicinae.
  - [x] 5.3 RED: Add one behavior check/eval that WSL host does not require Firefly-specific services/secrets/hardware.
  - [x] 5.4 GREEN: Keep `vindos` imports focused: WSL module, base/shell if safe, WSL-safe user module, and minimal packages only.
  - [x] 5.5 REFACTOR: If checks are too brittle by package name, move them to broader behavior assertions: no graphical-session user services, no desktop module imports, no hardware-specific options set.

- [ ] 6.0 Validate, format, and document user commands
  - [x] 6.1 RED: Add final behavior check path for full system toplevel evaluation:
    - `nix eval .#nixosConfigurations.vindos.config.system.build.toplevel.drvPath`
  - [x] 6.2 GREEN: Fix evaluation errors until toplevel derivation evaluates.
  - [x] 6.3 REFACTOR: Run `nix fmt` and keep diffs minimal.
  - [x] 6.4 GREEN: Run targeted validation:
    - `nix flake show`
    - `nix eval .#nixosConfigurations.vindos.config.networking.hostName`
    - `nix eval .#nixosConfigurations.vindos.config.wsl.defaultUser`
    - `nix eval .#nixosConfigurations.vindos.config.system.build.toplevel.drvPath`
  - [ ] 6.5 GREEN: If feasible, run broader validation:
    - `nix build .#nixosConfigurations.vindos.config.system.build.toplevel --dry-run`
    - `nix flake check`
  - [x] 6.6 GREEN: Add or update short usage notes somewhere appropriate if repo has docs convention; otherwise include commands in PR/commit notes:
    - `sudo nixos-rebuild switch --flake ~/nix-computers#vindos`
    - PowerShell after WSL config change: `wsl --shutdown; wsl -d vindos`

## Notes

- User chose v1 scope: manual NixOS-WSL host only. No `.wsl` tarball, installer, GitHub Actions, or corporate deployment automation.
- Host name: `vindos`.
- Default user: `monochromatti`.
- Desired feel: minimal `firefly`, terminal-only, no GUI tools, but keep nice WSL/Windows Terminal shell experience such as starship/zsh/direnv/fzf/zoxide where supported.
- Target channel: user selected NixOS-WSL recommended unstable. Start with `github:nix-community/NixOS-WSL/main`; if following repo `nixpkgs` breaks, prefer NixOS-WSL compatibility and document choice.
- Main design risk: existing `monochromatti` Home Manager profile imports GUI-heavy modules (`ghostty`, `zed`, `linux`, desktop packages/services). Do not blindly reuse it for WSL if it pulls GUI closure or broken services.
- Keep repo style: small composable Nix modules, minimal diffs, no broad refactor unless needed to separate CLI/dev packages from GUI packages.
- Validation nuance: use `path:.#...` during active local work. Plain `.#...` evaluates git tree and ignores untracked files, which hides newly added modules.
- `6.5` left open intentionally: `nix build path:.#nixosConfigurations.vindos.config.system.build.toplevel --dry-run` ran and passed after cleanup; full `nix flake check` not run due unrelated concurrent changes in `packages/` and `modules/ai/system.nix` from another agent.
- Follow-up cleanup split Home Manager packages into single-word domain aspects under `flake.modules.homeManager`: `development`, `terminal`, `documents`, `publishing`, `diagrams`, `containers`, `cloud`, `virtualization`, `desktop`, `security`, `apps`, plus composed profiles `wsl`, `workstation`, and compatibility/default `packages`. Composition uses namespace imports (`inputs.self.modules.homeManager.<aspect>`) instead of local module variables. WSL imports `wsl`; desktop `packages` still imports workstation + desktop/security extras.
