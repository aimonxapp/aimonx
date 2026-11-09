#!/bin/bash
#
# scripts/modifica/icona.sh — METTE SULLA SCRIVANIA L'ICONA che accende il sito
# in locale. Giro W37. Si lancia una volta per Mac (lo fa CC).
#
# ⛔ L'icona contiene il percorso di QUESTO repo su QUESTO Mac, e per questo
# non è un file del repo (WD17: nessun percorso di Pier in un file tracciato).
# Il percorso si calcola qui, al momento, e si scrive solo sulla Scrivania.
set -eu
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
ICONA="$HOME/Desktop/Sito AIMONX in locale.command"
{
  echo '#!/bin/bash'
  echo '# Accende il sito AIMONX su questo Mac. Scritta da scripts/modifica/icona.sh.'
  printf 'exec %q\n' "$REPO/scripts/modifica/accendi.sh"
} > "$ICONA"
chmod +x "$ICONA" "$REPO/scripts/modifica/accendi.sh"
echo "Icona scritta: $ICONA"
