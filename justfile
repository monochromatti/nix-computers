set shell := ["bash", "-euo", "pipefail", "-c"]

# Build vindos .wsl image locally.
build-wsl out="vindos.wsl":
  sudo nix run .#nixosConfigurations.vindos.config.system.build.tarballBuilder -- {{out}}

# Build checksum for image.
checksum file="vindos.wsl":
  sha256sum {{file}} > {{file}}.sha256

# Build image + checksum.
package-wsl out="vindos.wsl":
  just build-wsl {{out}}
  just checksum {{out}}

# Upload local artifacts to existing GitHub release tag.
upload-wsl tag out="vindos.wsl":
  gh release upload {{tag}} {{out}} {{out}}.sha256 --clobber
