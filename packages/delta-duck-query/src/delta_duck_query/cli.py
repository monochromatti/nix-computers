"""Minimal CLI to query Delta Lake via DuckDB."""

from __future__ import annotations

import argparse
import json
import re
import sys

import duckdb
from azure.identity import DefaultAzureCredential


def infer_account(path: str) -> str | None:
    m = re.match(r"^abfss://[^@]+@([^.]+)\.dfs\.core\.windows\.net", path)
    return m.group(1) if m else None


def quote_sql(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


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
    args = p.parse_args()

    sql = args.query or "SELECT * FROM delta_scan($source_path)"

    con = duckdb.connect(":memory:")
    for ext in ("delta", "azure", "httpfs"):
        con.install_extension(ext)
        con.load_extension(ext)

    if not args.no_auth and args.source_path.startswith("abfss://"):
        account = args.account or infer_account(args.source_path)
        if not account:
            sys.exit("Error: cannot infer Azure account; pass --account.")
        setup_azure(con, account)

    params = {"source_path": args.source_path} if "$source_path" in sql else {}
    rel = con.sql(sql, params=params)
    cols = [d[0] for d in rel.description]
    rows = [dict(zip(cols, r, strict=True)) for r in rel.fetchall()]
    json.dump(rows, sys.stdout, default=str)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
