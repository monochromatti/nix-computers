"""Query Delta Lake through DuckDB or a Quack server."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass
from typing import Any

import duckdb
from azure.identity import DefaultAzureCredential

CONFIG = {
    "dev": {
        "deltalake_account": "deltalake5111c8c6",
        "quack": {
            "host": "quack:quack-dev.fornybar.eviny.io:443",
            "scope": "https://apps.eviny.no/quack-dev/.default",
        },
    },
    "prod": {
        "deltalake_account": "deltalake584a2d66",
        "quack": {
            "host": "quack:quack.fornybar.eviny.io:443",
            "scope": "https://apps.eviny.no/quack/.default",
        },
    },
}


@dataclass(frozen=True)
class QuackConfig:
    host: str
    scope: str
    timeout: float = 300.0


def infer_account(path: str) -> str | None:
    m = re.match(r"^abfss://[^@]+@([^.]+)\.dfs\.core\.windows\.net", path)
    return m.group(1) if m else None


def quote_sql(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def load_config(environment: str) -> tuple[dict[str, Any], dict[str, Any]]:
    db = CONFIG[environment]
    return db, db.get("quack") or {}


def quack_config(
    config: dict[str, Any],
    host: str | None,
    scope: str | None,
    timeout: float | None,
) -> QuackConfig | None:
    host = host or os.environ.get("DB_QUACK_HOST") or config.get("host")
    scope = scope or os.environ.get("DB_QUACK_SCOPE") or config.get("scope")
    if not host and not scope:
        return None
    if not host or not scope:
        raise SystemExit("Error: Quack host and scope must be configured together.")
    timeout_value = timeout
    if timeout_value is None:
        timeout_value = float(
            os.environ.get("DB_QUACK_TIMEOUT", config.get("timeout", 300.0))
        )
    if not host.startswith("quack:"):
        raise SystemExit("Error: Quack host must start with 'quack:'.")
    if timeout_value <= 0:
        raise SystemExit("Error: Quack timeout must be positive.")
    return QuackConfig(host=host, scope=scope, timeout=timeout_value)


def setup_azure(con: duckdb.DuckDBPyConnection, account: str) -> None:
    token = (
        DefaultAzureCredential().get_token("https://storage.azure.com/.default").token
    )
    con.execute(
        "CREATE OR REPLACE SECRET ("
        "TYPE azure, "
        "PROVIDER access_token, "
        f"ACCESS_TOKEN {quote_sql(token)}, "
        f"ACCOUNT_NAME {quote_sql(account)}"
        ")"
    )


def setup_quack(con: duckdb.DuckDBPyConnection, config: QuackConfig) -> None:
    token = DefaultAzureCredential().get_token(config.scope).token
    con.execute(f"SET http_timeout = {config.timeout}")
    con.execute(f"ATTACH {quote_sql(config.host)} AS remote (TOKEN {quote_sql(token)})")


def render_remote_sql(sql: str, source_path: str) -> str:
    return sql.replace("$source_path", quote_sql(source_path))


def fetch_rows(rel: duckdb.DuckDBPyRelation) -> None:
    cols = [d[0] for d in rel.description]
    rows = [dict(zip(cols, row, strict=True)) for row in rel.fetchall()]
    json.dump(rows, sys.stdout, default=str)
    sys.stdout.write("\n")


def main() -> None:
    p = argparse.ArgumentParser(description="Query Delta Lake with DuckDB.")
    p.add_argument(
        "--source-path", required=True, help="Delta table path (abfss:// or local)."
    )
    p.add_argument(
        "--query",
        help="SQL. Use $source_path. Default: SELECT * FROM delta_scan($source_path).",
    )
    p.add_argument(
        "--account", help="Azure storage account (defaults: inferred from abfss URL)."
    )
    p.add_argument("--no-auth", action="store_true", help="Skip Azure auth.")
    p.add_argument(
        "--environment",
        choices=("dev", "prod"),
        default=os.environ.get("DELTA_DUCK_QUERY_ENV", "prod"),
        help="Bundled Quack configuration to use.",
    )
    p.add_argument("--quack-host", help="Quack server URI.")
    p.add_argument("--quack-scope", help="Entra scope used for Quack authentication.")
    p.add_argument("--quack-timeout", type=float, help="Quack HTTP timeout in seconds.")
    p.add_argument("--no-quack", action="store_true", help="Query Delta Lake locally.")
    args = p.parse_args()

    sql = args.query or "SELECT * FROM delta_scan($source_path)"
    db_config, quack_values = load_config(args.environment)
    remote = (
        None
        if args.no_quack
        else quack_config(
            quack_values,
            args.quack_host,
            args.quack_scope,
            args.quack_timeout,
        )
    )

    if remote and args.no_auth:
        sys.exit("Error: --no-auth cannot be used with Quack.")

    con = duckdb.connect(":memory:")
    if remote:
        con.install_extension("quack")
        con.load_extension("quack")
        setup_quack(con, remote)
        remote_sql = render_remote_sql(sql, args.source_path)
        fetch_rows(con.sql(f"SELECT * FROM remote.query({quote_sql(remote_sql)})"))
        return

    for ext in ("delta", "azure", "httpfs"):
        con.install_extension(ext)
        con.load_extension(ext)

    if not args.no_auth and args.source_path.startswith("abfss://"):
        account = (
            args.account
            or infer_account(args.source_path)
            or db_config.get("deltalake_account")
        )
        if not account:
            sys.exit("Error: cannot infer Azure account; pass --account.")
        setup_azure(con, account)

    params = {"source_path": args.source_path} if "$source_path" in sql else {}
    fetch_rows(con.sql(sql, params=params))


if __name__ == "__main__":
    main()
