#!/usr/bin/env bash
# Une los .sql en orden y arma el .zip de entrega (SQL + PDF del informe).
# Antes de correrlo: poner el informe final en docs/entrega/Informe_Final.pdf
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/entrega"
mkdir -p "$OUT"
SQL="$OUT/Proyecto3_PetitMonde.sql"
: > "$SQL"
# El orden se toma de run_all.sql
grep -E '^\\i ' "$ROOT/database/run_all.sql" | sed 's/^\\i //' | while read -r f; do
  echo "-- ============ $f ============" >> "$SQL"
  cat "$ROOT/database/$f" >> "$SQL"
  printf "\n\n" >> "$SQL"
done
cp "$ROOT/docs/entrega/Informe_Final.pdf" "$OUT/" 2>/dev/null || echo "AVISO: falta docs/entrega/Informe_Final.pdf"
rm -f "$OUT/Proyecto3_PetitMonde.zip"
if [ -f "$OUT/Informe_Final.pdf" ]; then
  ( cd "$OUT" && zip -q Proyecto3_PetitMonde.zip Proyecto3_PetitMonde.sql Informe_Final.pdf )
else
  ( cd "$OUT" && zip -q Proyecto3_PetitMonde.zip Proyecto3_PetitMonde.sql )
fi
echo "Listo: $OUT/Proyecto3_PetitMonde.zip"
