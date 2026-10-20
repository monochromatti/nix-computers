#!/usr/bin/env bash
# Usage: triage.sh FILE...  Scores each test with Decision-1; prints score, label, location, highest first.
set -euo pipefail
: "${AZURE_API_KEY:?}" "${AZURE_RESOURCE_NAME:?}"
skill="$(dirname "$(readlink -f "$0")")/SKILL.md"
py=python3; command -v python3 >/dev/null || py="nix shell nixpkgs#python3 --command python3"

$py - "$@" <<'EOF' |
import ast, json, sys
for f in sys.argv[1:]:
    src = open(f).read()
    if not f.endswith(".py"):
        print(json.dumps({"loc": f, "code": src[:20000]})); continue
    for n in ast.walk(ast.parse(src)):
        if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef)) and n.name.startswith("test"):
            print(json.dumps({"loc": f"{f}:{n.lineno}:{n.name}", "code": ast.get_source_segment(src, n)}))
EOF
while read -r t; do
  jq -n --rawfile skill "$skill" --argjson t "$t" '{model:"Decision-1",
    state:("RUBRIC:\n"+$skill+"\nTEST UNDER REVIEW ("+$t.loc+"):\n"+$t.code),
    questions:{
      tautological:{type:"noul",instructions:"Is this test tautological: would it stay green for realistic bugs in the production code it targets?",
        criteria:{"true":"The test cannot catch a realistic bug in the code it targets","false":"The test asserts observable behavior against an independent expected value"}},
      mode:{type:"choice",instructions:"Which description best fits the main weakness of this test?",
        criteria:{none:"Sound test",weak_assertion:"Asserts only existence, type, length, finiteness, or absence of crash",mirror:"Expected value computed with the logic under test",mocks_subject:"Patches the code under test itself",choreography:"Asserts internal call sequence instead of outcome",declaration:"Tests defaults, constants, inheritance, or assignment",upstream:"Tests a third-party library rather than our code"}}}}' |
  curl -sS --fail-with-body --retry 5 --retry-all-errors \
    -H "api-key: $AZURE_API_KEY" -H 'Content-Type: application/json' --data-binary @- \
    "https://${AZURE_RESOURCE_NAME}.services.ai.azure.com/providers/microsoft/v1/systemone" |
  jq -r --arg loc "$(jq -r .loc <<<"$t")" '[(.answers.tautological.noul*100|round), .answers.mode.choice, $loc] | @tsv'
done | sort -rn
