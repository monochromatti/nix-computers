#!/usr/bin/env bash
set -euo pipefail

noctalia=$1
"$noctalia" msg session lock >/dev/null
if ! "$noctalia" msg status | jq -e '.locked == true' >/dev/null; then
  printf '%s\n' 'Noctalia did not start locking; refusing to suspend.' >&2
  exit 1
fi
exec "$noctalia" msg session lock-and-suspend
