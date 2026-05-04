#!/usr/bin/env bash
# Deploy remoto: migrazioni (se link/password) + tutte le Edge Functions.
#
# 1) Autenticazione (una tantum): supabase login
# 2) Opzionale migrazioni DB: export SUPABASE_DB_PASSWORD='…' (Dashboard → Database)
# 3) Opzionale: export SUPABASE_PROJECT_REF='…' (default: progetto Vista già in uso nell’app)

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

REF="${SUPABASE_PROJECT_REF:-iutwiokumxyhvdaqgdwg}"

if ! supabase projects list >/dev/null 2>&1; then
  echo "Errore: non sei loggato in Supabase CLI. Esegui: supabase login" >&2
  exit 1
fi

if [[ -n "${SUPABASE_DB_PASSWORD:-}" ]]; then
  echo "==> Link progetto + db push…"
  supabase link --project-ref "$REF" --password "$SUPABASE_DB_PASSWORD" --yes
  supabase db push --yes
else
  echo "==> Salto db push (nessun SUPABASE_DB_PASSWORD)."
  echo "    Per applicare le migrazioni: export SUPABASE_DB_PASSWORD='…' e rilancia,"
  echo "    oppure incolla supabase/migrations/*.sql nel SQL Editor del dashboard."
  echo "    Se l’app dà «Bucket not found»: esegui anche supabase/fix_storage_bucket.sql"
fi

echo "==> Edge Functions (--project-ref $REF)…"
for fn in sendPointview getPointview getPointviewById getProfile; do
  echo "    → $fn"
  supabase functions deploy "$fn" --project-ref "$REF"
done

echo "Fatto."
