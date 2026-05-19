# delta-duck-query

Small CLI to query Delta Lake from DuckDB, based on auth/query pattern in `fornybar/hops`:

- Uses DuckDB extensions: `delta`, `azure`, `httpfs`
- Uses `delta_scan(...)` for Delta tables
- Uses Azure access-token auth via DuckDB `CREATE SECRET`
- Supports secret refs like hops `FlexibleSecretStr` style:
  - raw value
  - file path
  - KeyVault URI: `https://<vault>.vault.azure.net/secrets/<name>[/version]`

## Usage

```bash
delta-duck-query \
  --source-path 'abfss://container@account.dfs.core.windows.net/path/to/table' \
  --query 'select * from delta_scan($source_path) limit 10'
```

With KeyVault-backed account name:

```bash
delta-duck-query \
  --source-path 'abfss://container@account.dfs.core.windows.net/path/to/table' \
  --account-ref 'https://myvault.vault.azure.net/secrets/deltalake-account' \
  --query 'select count(*) as n from delta_scan($source_path)'
```

If `--token-ref` missing, tool gets token via `DefaultAzureCredential` for scope `https://storage.azure.com/.default`.
