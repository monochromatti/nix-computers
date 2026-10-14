{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      package = pkgs.buildNpmPackage {
        pname = "pi-subagent-manager";
        version = "0.29.0";

        src = pkgs.fetchFromGitHub {
          owner = "championswimmer";
          repo = "pi-subagent-manager";
          rev = "092627be6f3696b3897767d896ef7309c01e48ca";
          hash = "sha256-Sk/N8Quz1Q6FyV2BlSW5k5s3u8wWMeZ4xzQBVNw/7Ew=";
        };

        npmDepsHash = "sha256-ApxzbXdzCq7JVOAVhJH7dV6Yra+VSSMgDnkZy4XdkJw=";
        npmDepsFetcherVersion = 2;
        postPatch = ''
          cp ${./locks/pi-subagent-manager.json} package-lock.json
          rm -f agents/*.md
          cp ${../agents}/*.md agents/
          chmod u+w agents/*.md
          for role in engineer verifier worker; do
            ${lib.getExe pkgs.python3} - "agents/$role.md" ${../SYSTEM.md} <<'PY'
          import pathlib
          import sys
          path = pathlib.Path(sys.argv[1])
          header, body = path.read_text().split("---", 2)[1:]
          path.write_text("---" + header + "---\n\n" + pathlib.Path(sys.argv[2]).read_text() + body)
          PY
          done
        '';
        dontNpmBuild = true;
        doCheck = true;
        checkPhase = ''
          node --input-type=module <<'JS'
          import assert from 'node:assert/strict';
          import { readFileSync, lstatSync, readdirSync } from 'node:fs';
          import { parse } from 'yaml';
          const roles = ['deep-reviewer', 'engineer', 'fast-reviewer', 'oracle', 'planner', 'researcher', 'scout', 'verifier', 'worker'];
          assert.deepEqual(readdirSync('agents').filter((name) => name.endsWith('.md')).sort(), roles.map((role) => `''${role}.md`).sort());
          for (const role of roles) {
            const path = `agents/''${role}.md`;
            assert(lstatSync(path).isFile());
            const [, header, body] = readFileSync(path, 'utf8').split('---');
            const agent = parse(header);
            assert.equal(agent.name, role);
            assert.equal(agent.models.length, 1);
            assert(agent.thinkingLevel);
            assert(agent.tools.allow.includes('agent_pause'));
            assert(!agent.tools.allow.includes('agent_spawn'));
            assert(!body.includes('caller_ping'));
            if (['engineer', 'verifier', 'worker'].includes(role)) {
              assert(body.includes('# System notes'));
            }
          }
          JS
        '';
        installPhase = ''
          mkdir -p "$out"
          cp -R ./. "$out/"
        '';

        meta = {
          description = "Hierarchical, steerable Pi subagent threads with custom roles";
          homepage = "https://github.com/championswimmer/pi-subagent-manager";
          license = lib.licenses.mit;
        };
      };
    in
    {
      packages.pi-subagent-manager = package;
      pi.extensions = [ package ];
    };
}
