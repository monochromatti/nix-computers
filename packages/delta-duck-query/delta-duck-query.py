#!/usr/bin/env python3
import argparse
import contextlib
import csv
import io
import json
import os
import re
import sys
import tempfile
from pathlib import Path

import duckdb
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient


KEYVAULT_PATTERN = re.compile(
    r"^(https://[^/]+\.vault\.azure\.net/)secrets/([^/]+)(?:/([^/]+))?/?$"
)


def parse_param(raw: str) -> tuple[str, object]:
    if "=" not in raw:
        raise ValueError(f"Expected key=value, got: {raw}")
    key, value = raw.split("=", 1)
    if not key:
        raise ValueError(f"Missing key in param: {raw}")
    try:
        return key, json.loads(value)
    except json.JSONDecodeError:
        return key, value


def infer_account_from_abfss(path: str) -> str | None:
    match = re.match(r"^abfss://[^@]+@([^.]+)\.dfs\.core\.windows\.net(?:/|$)", path)
    if match:
        return match.group(1)
    return None


def sql_quote(value: str) -> str:
    quote = "'"
    return quote + value.replace(quote, quote + quote) + quote


def resolve_secret_ref(value: str) -> str:
    with contextlib.suppress(OSError):
        maybe_path = Path(value)
        if maybe_path.exists():
            return maybe_path.read_text(encoding="utf-8").rstrip("\n")

    match = KEYVAULT_PATTERN.search(value)
    if match:
        vault_url = match.group(1)
        secret_name = match.group(2)
        version = match.group(3)
        credential = DefaultAzureCredential()
        client = SecretClient(vault_url=vault_url, credential=credential)
        secret = client.get_secret(secret_name, version=version).value
        if secret is None:
            raise SystemExit(f"KeyVault secret {secret_name} returned None")
        return secret

    return value


def load_extensions(con: duckdb.DuckDBPyConnection) -> None:
    try:
        con.install_extension("delta")
        con.install_extension("azure")
        con.install_extension("httpfs")
    except duckdb.IOException:
        extension_directory = (
            Path(tempfile.gettempdir())
            / "duckdb"
            / "extensions"
            / duckdb.__version__
        )
        con.execute(f"SET extension_directory = {sql_quote(str(extension_directory))}")
        con.install_extension("delta")
        con.install_extension("azure")
        con.install_extension("httpfs")

    con.load_extension("delta")
    con.load_extension("azure")
    con.load_extension("httpfs")
    con.execute("SET enable_http_metadata_cache = true")
    con.execute("SET TimeZone = 'UTC'")


def first_abfss_path(query: str, params: dict[str, object]) -> str | None:
    for value in params.values():
        if isinstance(value, str) and value.startswith("abfss://"):
            return value

    match = re.search(r"abfss://[^'\"\s)]+", query)
    if match:
        return match.group(0)

    return None


def get_storage_token(token_ref: str | None) -> str:
    if token_ref:
        return resolve_secret_ref(token_ref)

    return DefaultAzureCredential().get_token(
        "https://storage.azure.com/.default"
    ).token


parser = argparse.ArgumentParser(
    prog="delta-duck-query",
    description=(
        "Query Delta Lake with DuckDB. "
        "Built for AI-agent use. "
        "Follows HOPS pattern: delta_scan + DuckDB Azure SECRET auth."
    ),
    formatter_class=argparse.RawTextHelpFormatter,
    epilog=(
        "How auth works (abfss:// paths):\n"
        "  1) Resolve account name from --account-ref/--account, or DB_DELTALAKE_ACCOUNT,\n"
        "     or infer from source path.\n"
        "  2) Resolve token from --token-ref/--token or DB_DELTALAKE_TOKEN.\n"
        "  3) If token missing, fetch via DefaultAzureCredential() with\n"
        "     scope https://storage.azure.com/.default.\n"
        "  4) Create DuckDB Azure secret and run query.\n\n"
        "Secret ref format (same style as hops FlexibleSecretStr):\n"
        "  - Raw value\n"
        "  - File path (reads file content)\n"
        "  - KeyVault URI: https://<vault>.vault.azure.net/secrets/<name>[/version]\n\n"
        "Examples:\n"
        "  # 1) Local Delta table\n"
        "  delta-duck-query --source-path ./data/my_delta --format table\n\n"
        "  # 2) Azure path, account from KeyVault, token from DefaultAzureCredential\n"
        "  delta-duck-query \\\n"
        "    --source-path 'abfss://container@account.dfs.core.windows.net/table' \\\n"
        "    --account-ref 'https://myvault.vault.azure.net/secrets/deltalake-account' \\\n"
        "    --query 'select count(*) as n from delta_scan($source_path)'\n\n"
        "  # 3) Query file with params\n"
        "  delta-duck-query \\\n"
        "    --query-file ./query.sql \\\n"
        "    --param start='\"2026-01-01T00:00:00Z\"' \\\n"
        "    --param n=100\n"
    ),
)
parser.add_argument(
    "--db",
    default=":memory:",
    help="DuckDB file path. Use :memory: for ephemeral DB (default).",
)
parser.add_argument(
    "--source-path",
    help=(
        "Delta table path. Supports local paths and abfss:// URLs. "
        "If set without --query/--query-file, default query becomes "
        "SELECT * FROM delta_scan($source_path)."
    ),
)
parser.add_argument(
    "--query",
    help="SQL query text. Can use named params like $source_path and pass via --param.",
)
parser.add_argument(
    "--query-file",
    help="Path to SQL file. Mutually exclusive with --query.",
)
parser.add_argument(
    "--param",
    action="append",
    default=[],
    metavar="KEY=VALUE",
    help=(
        "Named SQL param: KEY=VALUE. "
        "VALUE parsed as JSON first (numbers/bools/arrays/objects), "
        "falls back to raw string. Repeat flag for multiple params."
    ),
)
parser.add_argument(
    "--format",
    choices=["json", "jsonl", "csv", "table"],
    default="json",
    help="Output format: json, jsonl, csv, or table. Default: json.",
)
parser.add_argument(
    "--output",
    help="Write result to file path. If omitted, prints to stdout.",
)

parser.add_argument(
    "--account-ref",
    help=(
        "Azure Storage account ref: raw value, file path, or KeyVault URI "
        "(https://<vault>.vault.azure.net/secrets/<name>[/version])."
    ),
)
parser.add_argument("--account", help="Alias for --account-ref.")
parser.add_argument(
    "--token-ref",
    help=(
        "Optional access-token ref (raw/file/KeyVault URI). If missing, tool uses "
        "DefaultAzureCredential().get_token('https://storage.azure.com/.default')."
    ),
)
parser.add_argument("--token", help="Alias for --token-ref.")
parser.add_argument(
    "--no-auth",
    action="store_true",
    help="Skip Azure secret setup entirely (useful for local/non-Azure paths).",
)

args = parser.parse_args()

if args.query and args.query_file:
    parser.error("Use either --query or --query-file, not both")

if args.query_file:
    query = Path(args.query_file).read_text(encoding="utf-8")
elif args.query:
    query = args.query
elif args.source_path:
    query = "SELECT * FROM delta_scan($source_path)"
else:
    parser.error("Provide --query/--query-file or --source-path")

params: dict[str, object] = {}
if args.source_path:
    params["source_path"] = args.source_path

for raw in args.param:
    key, value = parse_param(raw)
    params[key] = value

con = duckdb.connect(args.db)
load_extensions(con)

source_path = first_abfss_path(query, params)
needs_auth = not args.no_auth and source_path is not None

if needs_auth:
    account_ref = (
        args.account_ref
        or args.account
        or os.environ.get("DB_DELTALAKE_ACCOUNT", "").strip()
        or infer_account_from_abfss(source_path)
    )
    token_ref = args.token_ref or args.token or os.environ.get("DB_DELTALAKE_TOKEN")

    if not account_ref:
        raise SystemExit(
            "Missing Azure account ref. Pass --account-ref/--account or set DB_DELTALAKE_ACCOUNT."
        )

    account_name = resolve_secret_ref(account_ref)
    if not account_name:
        raise SystemExit("Resolved Azure account empty")

    token = get_storage_token(token_ref)
    if not token:
        raise SystemExit("Resolved Azure token empty")

    con.execute(
        f"""
        CREATE OR REPLACE SECRET(
            TYPE azure,
            PROVIDER access_token,
            ACCESS_TOKEN {sql_quote(token)},
            ACCOUNT_NAME {sql_quote(account_name)}
        );
        """
    )

rel = con.sql(query, params=params)
columns = [desc[0] for desc in rel.description]
rows = rel.fetchall()

if args.format == "json":
    output = json.dumps([dict(zip(columns, row, strict=True)) for row in rows], default=str)
elif args.format == "jsonl":
    output = "\n".join(
        json.dumps(dict(zip(columns, row, strict=True)), default=str) for row in rows
    )
elif args.format == "csv":
    csv_buffer = io.StringIO()
    writer = csv.writer(csv_buffer)
    writer.writerow(columns)
    writer.writerows(rows)
    output = csv_buffer.getvalue().rstrip("\r\n")
else:
    lines = ["\t".join(columns)]
    for row in rows:
        lines.append("\t".join("" if value is None else str(value) for value in row))
    output = "\n".join(lines)

if args.output:
    Path(args.output).write_text(output + ("" if output.endswith("\n") else "\n"), encoding="utf-8")
else:
    sys.stdout.write(output)
    if not output.endswith("\n"):
        sys.stdout.write("\n")
