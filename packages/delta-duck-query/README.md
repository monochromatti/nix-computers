# delta-duck-query

Query Delta Lake with the DuckDB 2.0 alpha client and the bundled Quack configuration.

The production configuration is the default. Select development with `--environment dev` or `DELTA_DUCK_QUERY_ENV=dev`.

```bash
delta-duck-query \
  --source-path 'abfss://container@account.dfs.core.windows.net/path/to/table' \
  --query 'select * from delta_scan($source_path) limit 10'
```

The bundled production endpoint is `quack:quack.fornybar.eviny.io:443` with scope `https://apps.eviny.no/quack/.default`. The development endpoint is `quack:quack-dev.fornybar.eviny.io:443` with scope `https://apps.eviny.no/quack-dev/.default`.

Use `--quack-host` and `--quack-scope` to override the bundled values. Use `--no-quack` to run the query locally. Local Azure authentication uses `DefaultAzureCredential`.

Output: JSON array to stdout.
