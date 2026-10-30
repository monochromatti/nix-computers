{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      package = pkgs.buildNpmPackage {
        pname = "pi-subagents";
        version = "0.84.0";

        src = pkgs.fetchFromGitHub {
          owner = "nicobailon";
          repo = "pi-subagents";
          rev = "0398b9e8d6f03dc6054dbf13dfe851c7a20bff3a";
          hash = "sha256-yJHclk8TqJX0OGDteZYAbcW9qGDY9a8BSVy0kxcRpEU=";
        };

        npmDepsHash = "sha256-g4QnfXCzx5d+punmLPSzQJbX4ErZFj3oSop5kzDWcD4=";
        npmDepsFetcherVersion = 2;
        postPatch = ''
          cp ${./locks/pi-subagents.json} package-lock.json
          rm -f agents/*.md
          cp ${../agents}/*.md agents/
          chmod u+w agents/*.md
          for role in engineer verifier worker; do
            ${lib.getExe pkgs.nodejs} - "agents/$role.md" ${../SYSTEM.md} <<'JS'
          const fs = require('fs');
          const [file, system] = process.argv.slice(2);
          const [, header, ...body] = fs.readFileSync(file, 'utf8').split('---');
          fs.writeFileSync(file, '---' + header + '---\n\n' + fs.readFileSync(system, 'utf8') + body.join('---'));
          JS
          done
          ${lib.getExe pkgs.jq} '."pi-subagents".agents = ["./agents"]' package.json > package.json.new
          mv package.json.new package.json
          for skill in skills/*/SKILL.md; do
            sed -i "0,/^---$/s//---\ndisable-model-invocation: true/" "$skill"
          done
        '';
        dontNpmBuild = true;
        doCheck = true;
        checkPhase = ''
          node --input-type=module <<'JS'
          import assert from 'node:assert/strict';
          import { readFileSync, readdirSync } from 'node:fs';
          import { parse } from 'yaml';
          const roles = ['deep-reviewer', 'engineer', 'fast-reviewer', 'oracle', 'planner', 'researcher', 'scout', 'verifier', 'visual-scout', 'worker'];
          assert.deepEqual(readdirSync('agents').filter((name) => name.endsWith('.md')).sort(), roles.map((role) => `''${role}.md`).sort());
          for (const role of roles) {
            const [, header, body] = readFileSync(`agents/''${role}.md`, 'utf8').split('---');
            const agent = parse(header);
            assert.equal(agent.name, role);
            assert.match(agent.model, /^[a-z-]+\//);
            assert(agent.thinking);
            assert(!agent.tools.includes('agent_pause'));
            assert(!body.includes('agent_update'));
            if (['engineer', 'verifier', 'worker'].includes(role)) {
              assert(readFileSync(`agents/''${role}.md`, 'utf8').includes('# System notes'));
            }
          }
          JS
        '';
        installPhase = ''
          mkdir -p "$out"
          cp -R ./. "$out/"
        '';

        meta = {
          description = "Pi extension for single-agent delegation and scripted multi-agent workflows";
          homepage = "https://github.com/nicobailon/pi-subagents";
          license = lib.licenses.mit;
        };
      };
    in
    {
      packages.pi-subagents = package;
      pi.extensions = [ package ];
    };
}
