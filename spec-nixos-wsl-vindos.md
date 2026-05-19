# Spec: NixOS-WSL Host `vindos`

## Introduction / overview

Add a new NixOS-WSL host named `vindos` to this flake repository.

Goal: make a Windows Subsystem for Linux environment that feels like a minimal, terminal-only version of the existing `firefly` host. It should keep the useful shell and developer experience pieces (`zsh`, `starship`, `direnv`, common CLI/dev packages, Home Manager user setup) while avoiding GUI, desktop, hardware, and laptop-specific modules that do not make sense in WSL.

This first version is intentionally simple: it should support manual installation/rebuild with `nixos-rebuild --flake`, not prebuilt `.wsl` tarball generation or a Windows installer.

## Goals

1. Add `nixos-wsl` support to the flake inputs and wire it into a new NixOS host.
2. Create a new host configuration named `vindos`.
3. Set WSL default user to `monochromatti`.
4. Reuse safe terminal/developer modules from `firefly` where appropriate.
5. Avoid GUI, graphical-session, desktop, hardware, secrets, and laptop/work-specific modules in the WSL host.
6. Keep implementation consistent with current dendritic module style in `modules/`.
7. Provide clear commands for first install and day-to-day rebuilds.

## Functional requirements

1. The flake must include `nixos-wsl` as an input.
   - Recommended source: `github:nix-community/NixOS-WSL/main`.
   - Its `nixpkgs` input should follow the repository `nixpkgs` input when supported.

2. The flake must expose `nixosConfigurations.vindos`.
   - It should use existing `inputs.self.lib.mkNixos "x86_64-linux" "vindos"` pattern unless that helper cannot support WSL cleanly.

3. The new host must live under `modules/hosts/vindos/`.
   - Primary entrypoint should be `modules/hosts/vindos/default.nix`.
   - Additional focused files may be added only if useful, e.g. `wsl.nix` or `packages.nix`.

4. The `vindos` host must import `inputs.nixos-wsl.nixosModules.default`.

5. The `vindos` host must enable WSL.
   - Set `wsl.enable = true`.
   - Set `wsl.defaultUser = "monochromatti"`.
   - Set `networking.hostName = "vindos"`.

6. The `vindos` host must enable flakes and new nix command support.
   - Ensure `nix.settings.experimental-features = [ "nix-command" "flakes" ];` is configured.
   - This may go in the host module or a shared module if already available.

7. The `vindos` host must create/configure user `monochromatti` through existing repository user conventions.
   - Reuse `inputs.self.modules.nixos.monochromatti` if safe.
   - User metadata should match `firefly` where relevant:
     - `fullName = "Mattias Matthiesen"`
     - `email = "mattias.matthiesen@eviny.no"`
     - `git.userName = "monochromatti"`
     - `home-manager.enable = true`

8. The `vindos` host must include terminal-focused shared modules.
   - Reuse existing `base` if compatible with WSL.
   - Reuse existing `shell` module to get shell packages, aliases, `direnv`, `starship`, and `zsh`.
   - Include enough packages/modules to make WSL feel close to `firefly` for terminal use.

9. The `vindos` host must not import desktop or hardware modules.
   - Do not import `hardware`, `niri`, desktop modules, Firefly-specific hardware modules, or PC laptop modules.
   - Do not enable graphical shell/session services.

10. The `vindos` host should avoid GUI-only Home Manager modules and packages.
    - Existing `modules/users/monochromatti/default.nix` currently imports Home Manager modules such as `ghostty`, `zed`, `linux`, and `packages`.
    - Implementation must decide whether this is safe as-is or needs a WSL-specific Home Manager user module.
    - If existing Home Manager package set pulls GUI apps like `bitwarden-desktop`, `spotify`, `obsidian`, `libreoffice`, `gimp`, or desktop services, `vindos` must avoid those imports.

11. The implementation should provide a WSL-safe Home Manager profile for `monochromatti` if needed.
    - It should include terminal/dev packages from the normal profile where useful, e.g. Nix tooling, Rust/Python/JS tools, `gh`, `git`, `eza`, `ripgrep`, `glow`, `pandoc`, etc.
    - It should exclude GUI apps and desktop/session services.
    - It should preserve shell comfort: starship prompt, zsh, direnv, fzf, zoxide, aliases where supported.

12. The host should use a NixOS-WSL-compatible state version.
    - User selected current NixOS-WSL recommended unstable behavior.
    - Use current repository convention if compatible, otherwise set explicit `system.stateVersion` matching expected NixOS-WSL release guidance.
    - Document chosen value in implementation notes or comments if non-obvious.

13. The implementation must keep the first version manual-install only.
    - Do not add `.wsl` tarball builder outputs.
    - Do not add GitHub Actions for release artifacts.
    - Do not add PowerShell installer.

## Non-goals / out of scope

1. No prebuilt `.wsl` image generation in this change.
2. No Windows installer, PowerShell installer, MSI/MSIX packaging, or GitHub release automation.
3. No Docker setup unless already harmlessly inherited; do not make Docker a core requirement for v1.
4. No GUI desktop support, WSLg tuning, Wayland/X11 setup, Niri, Noctalia, Ghostty, Zed GUI integration, or graphical app bundles.
5. No corporate deployment hardening in v1.
   - Defender exclusions, SmartScreen signing, proxy policy, Intune packaging, and internal binary cache remain future work.
6. No broad refactor of existing host/user module structure unless necessary to prevent GUI packages from entering `vindos`.
7. No secrets wiring unless required for basic shell/dev behavior and confirmed safe for WSL.

## Technical considerations

### Existing repository structure

Relevant current files/modules:

- `flake.nix`: top-level flake inputs and flake-parts import tree.
- `modules/lib.nix`: exposes `mkNixos`, `mkDarwin`, package sets, and user paths.
- `modules/hosts/firefly/default.nix`: existing Linux host to model terminal/dev behavior from.
- `modules/nixos/base.nix`: shared NixOS base module with Home Manager, SOPS, AI module import, Nix settings, zsh, direnv, packages, fonts.
- `modules/shell/shell.nix`: imports shell packages, aliases, direnv, starship, zsh.
- `modules/shell/starship.nix`: shared starship prompt settings.
- `modules/shell/zsh.nix`: shared zsh setup.
- `modules/users/monochromatti/default.nix`: Home Manager wiring for user.
- `modules/home-manager/packages.nix`: includes both terminal/dev packages and GUI packages.
- `modules/home-manager/linux.nix`: includes desktop/graphical configuration and user services.

### Key risk: existing Home Manager profile is GUI-heavy

The current `monochromatti` Home Manager module imports:

- `packages`
- `ghostty`
- `zed`
- `linux`
- `userdirs`

Some of these are likely not appropriate for WSL terminal-only use. `packages.nix` also mixes CLI/dev tools with GUI apps. `linux.nix` configures GTK, Qt, desktop services, Noctalia, Vicinae, and Niri-related activation files.

Implementation should not blindly import the existing `monochromatti` NixOS module if that causes GUI closure bloat or broken WSL services. Prefer one of these approaches:

1. Add a WSL-specific Home Manager module for `monochromatti`, e.g. `flake.modules.homeManager.monochromatti-wsl`.
2. Or refactor existing Home Manager modules into smaller reusable pieces, e.g. terminal/dev packages vs GUI packages, then import only safe pieces for WSL.

Pick minimal diff. Avoid broad refactor unless needed.

### Suggested module composition

A likely `vindos` host composition:

```nix
{ inputs, ... }:
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "vindos";

  flake.modules.nixos.vindos = {
    imports = with inputs.self.modules.nixos; [
      inputs.nixos-wsl.nixosModules.default
      base
      shell
      # WSL-safe user/home-manager module for monochromatti
    ];

    wsl = {
      enable = true;
      defaultUser = "monochromatti";
    };

    networking.hostName = "vindos";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # user metadata using midgard.pc conventions if required by existing modules

    system.stateVersion = "...";
  };
}
```

Actual code should follow existing conventions and pass evaluation.

### NixOS-WSL input wiring

Add to `flake.nix` inputs:

```nix
nixos-wsl = {
  url = "github:nix-community/NixOS-WSL/main";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

If NixOS-WSL input compatibility with `nixos-25.11` is problematic, use its default nixpkgs or follow `nixpkgs-unstable`. Because user selected NixOS-WSL recommended unstable, prefer compatibility with `main` over forcing the repo release branch if eval fails.

### Install/rebuild user flow

Expected first-time setup after user imports base NixOS-WSL or otherwise has working NixOS-WSL shell:

```bash
sudo nixos-rebuild switch --flake path:/path/to/nix-computers#vindos
```

After WSL config changes:

```powershell
wsl --shutdown
wsl -d vindos
```

Day-to-day rebuild:

```bash
sudo nixos-rebuild switch --flake ~/nix-computers#vindos
```

## Success metrics / validation

1. `nix flake show` includes `nixosConfigurations.vindos`.
2. Targeted evaluation succeeds:

```bash
nix eval .#nixosConfigurations.vindos.config.system.build.toplevel.drvPath
```

3. If practical, build dry run succeeds:

```bash
nix build .#nixosConfigurations.vindos.config.system.build.toplevel --dry-run
```

4. No desktop/hardware modules are imported by `vindos`.
   - Confirm no imports of `niri`, `desktop`, Firefly hardware, `nixos-hardware`, PC laptop modules, Noctalia service modules, or GUI-only package modules unless explicitly justified.

5. WSL options evaluate as expected:
   - `wsl.enable == true`
   - `wsl.defaultUser == "monochromatti"`
   - `networking.hostName == "vindos"`

6. Shell comfort features are present:
   - `programs.zsh.enable == true`
   - `programs.starship.enable == true`
   - `programs.direnv.enable == true`
   - expected CLI packages available in system or Home Manager profile.

7. GUI-heavy packages are absent from WSL profile unless explicitly kept for terminal use.
   - Examples to avoid: `spotify`, `obsidian`, `libreoffice`, `gimp`, `inkscape`, `bitwarden-desktop`, `ghostty`, `zed` GUI package, Noctalia/Vicinae services.

8. Formatting passes after Nix edits:

```bash
nix fmt
```

9. Broader check passes if not too expensive:

```bash
nix flake check
```

If `nix flake check` is too slow, document targeted eval/build results instead.

## Future work

1. Add buildable `.wsl` tarball output for easier non-expert setup.
2. Add signed/internal PowerShell installer or MSI/MSIX for company deployment.
3. Add IT-facing rollout documentation for WSL policy, Defender exclusions, proxy allowlists, and binary cache access.
4. Add internal binary cache or Cachix cache for faster corporate installs.
5. Add optional Docker/devcontainer support once base WSL host is stable.
