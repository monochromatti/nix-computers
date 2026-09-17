#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

update() {
  local file=$1 owner=$2 repo=$3 npm=$4
  local rev url archive source hash version dir lock npmhash
  rev=$(git ls-remote "https://github.com/$owner/$repo.git" HEAD | cut -f1)
  test -n "$rev"
  url="https://github.com/$owner/$repo/archive/$rev.tar.gz"
  archive="$tmp/$repo.tar.gz"
  dir="$tmp/$repo"
  curl --fail --location --silent --show-error "$url" -o "$archive"
  hash=$(nix run nixpkgs#nix-prefetch-github -- "$owner" "$repo" --rev "$rev" | jq -r .hash)
  mkdir "$dir"
  tar -xzf "$archive" -C "$dir" --strip-components=1
  version=$(jq -r '.version // empty' "$dir/package.json" 2>/dev/null || true)
  if [[ -z "$version" ]]; then
    version=$(sed -n 's/.*version = "\([^"]*\)";.*/\1/p' "$root/$file" | head -1)
  fi
  if [[ "$npm" == 1 ]]; then
    lock="$root/locks/$repo.json"
    if [[ -f "$dir/package-lock.json" ]]; then
      cp "$dir/package-lock.json" "$lock"
    else
      (cd "$dir" && npm install --package-lock-only --ignore-scripts --no-audit --no-fund)
      cp "$dir/package-lock.json" "$lock"
    fi
    python3 - "$lock" <<'PY'
import json
import subprocess
import sys
path = sys.argv[1]
data = json.load(open(path))
for name, package in data.get("packages", {}).items():
    resolved = package.get("resolved", "")
    if not name or not resolved.startswith("https://registry.npmjs.org/") or "integrity" in package:
        continue
    package_name = name.removeprefix("node_modules/")
    if "/node_modules/" in package_name:
        package_name = package_name.rsplit("/node_modules/", 1)[1]
    integrity = subprocess.check_output(
        ["npm", "view", f"{package_name}@{package['version']}", "dist.integrity"],
        text=True,
    ).strip()
    if integrity:
        package["integrity"] = integrity
open(path, "w").write(json.dumps(data, indent=2) + "\n")
PY
    npmhash=$(nix run nixpkgs#prefetch-npm-deps -- "$lock")
  fi
  python3 - "$root/$file" "$rev" "$hash" "$version" "${npmhash-}" <<'PY'
import re
import sys
path, rev, source_hash, version, npm_hash = sys.argv[1:]
s = open(path).read()
s = re.sub(r'(rev = )"[^"]+";', rf'\1"{rev}";', s, count=1)
s = re.sub(r'(hash = )"[^"]+";', rf'\1"sha256-{source_hash}";', s, count=1)
s = re.sub(r'(version = )"[^"]+";', rf'\1"{version}";', s, count=1)
if npm_hash:
    s = re.sub(r'(npmDepsHash = )"[^"]+";', rf'\1"{npm_hash}";', s, count=1)
open(path, 'w').write(s)
PY
}

update herdr-lazygit.nix Crokily herdr-lazygit 0
update pi-herdr-subagents.nix modem-dev pi-herdr-subagents 0
update pi-impeccable.nix jordi9 pi-impeccable 0
update pi-mcp-adapter.nix nicobailon pi-mcp-adapter 1
update pi-ponytail.nix DietrichGebert ponytail 0
update pi-pretty.nix heyhuynhgiabuu pi-pretty 1
update pi-prompt-template-model.nix nicobailon pi-prompt-template-model 1
update pi-web-access.nix nicobailon pi-web-access 1
