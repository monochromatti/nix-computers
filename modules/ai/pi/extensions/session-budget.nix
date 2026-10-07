{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks.pi-session-budget =
        pkgs.runCommand "pi-session-budget-tests" { nativeBuildInputs = [ pkgs.nodejs ]; }
          ''
            cp ${./session-budget.ts} session-budget.ts
            cp ${./session-budget-usage.ts} session-budget-usage.ts
            cp ${./session-budget.test.ts} session-budget.test.ts
            printf '{"type":"module"}' > package.json
            node --test session-budget.test.ts
            touch "$out"
          '';
    };
}
