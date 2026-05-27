# delta-duck-query

Minimal CLI to query Delta Lake via DuckDB.

- DuckDB extensions: `delta`, `azure`, `httpfs`
- Azure auth via `DefaultAzureCredential` → DuckDB `CREATE SECRET`
- Account inferred from `abfss://` URL when possible

## Usage

```bash
delta-duck-query \
  --source-path 'abfss://container@account.dfs.core.windows.net/path/to/table' \
  --query 'select * from delta_scan($source_path) limit 10'
```

Local / non-Azure:

```bash
delta-duck-query --source-path ./local-table --no-auth
```

Output: JSON array to stdout.
