#!/usr/bin/env bash
# Uso:
#   bash scripts/db-run.sh                 -> reconstruye TODO desde cero (run_all.sql)
#   bash scripts/db-run.sh archivo.sql     -> ejecuta un solo archivo de database/
#   bash scripts/db-run.sh --shell         -> abre psql
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ -f "$ROOT/.env" ]; then set -a; source "$ROOT/.env"; set +a; fi
cd "$ROOT/database"
case "${1:-}" in
  --shell) exec psql ;;
  "")      psql -v ON_ERROR_STOP=1 -f run_all.sql ;;
  *)       psql -v ON_ERROR_STOP=1 -f "$1" ;;
esac
