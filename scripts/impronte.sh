#!/bin/bash
#
# scripts/impronte.sh — L'IMPRONTA DI OGNI FOGLIO DI STILE E DI OGNI SCRIPT.
# Giro W25→W26 (la coda di Cowork, punto 1).
#
# ⭐ PERCHÉ: i fogli e `menu.js` avevano sempre lo stesso indirizzo anche
# quando cambiavano, e il browser di chi era già passato poteva tenere in
# memoria i vecchi — dopo il W25 Pier vedeva le larghezze di prima. Adesso
# ogni indirizzo porta `?v=<impronta>`, i primi 10 caratteri dello SHA-256 del
# file COSTRUITO: cambia quando cambia il file, e solo allora.
# ⛔ NON L'ORA DELLA BUILD: cambierebbe a ogni build, e la build di Pages non
# sarebbe più identica al byte a quella locale. L'impronta del contenuto è la
# stessa ovunque il file sia costruito uguale.
#
# ⚠️ DUE PASSI, e perché bastano: 1) si costruisce, 2) questo script scrive
# le impronte in `_data/impronte.yml`, 3) si ricostruisce. I fogli non
# contengono le impronte, quindi il secondo giro non le cambia.
# ⛔ Chi cambia un foglio e dimentica di rifarle lo trova la controprova
# (`impronte_scadute`): ogni `?v=` del sito costruito deve essere l'impronta
# del file a cui punta.
#
# Uso:  scripts/impronte.sh _site      → riscrive _data/impronte.yml
set -euo pipefail
SITO="${1:?Uso: scripts/impronte.sh <sito costruito>}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
{
  echo "# _data/impronte.yml — SCRITTO DA scripts/impronte.sh, non a mano."
  echo "# L'impronta (SHA-256, 10 caratteri) di ogni foglio e script costruito:"
  echo "# va in coda al suo indirizzo, \`?v=…\` (\`_includes/testa.html\`)."
  (cd "$SITO" && find assets/css assets/js -type f \( -name '*.css' -o -name '*.js' \) | LC_ALL=C sort) |
  while read -r F; do
    echo "\"/$F\": \"$(shasum -a 256 "$SITO/$F" | cut -c1-10)\""
  done
} > "$REPO/_data/impronte.yml"
cat "$REPO/_data/impronte.yml" | grep -v '^#'
