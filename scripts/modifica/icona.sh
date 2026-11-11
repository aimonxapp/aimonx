#!/bin/bash
#
# scripts/modifica/icona.sh — METTE SULLA SCRIVANIA L'ICONA DEL BANCO AIMONX, che
# accende il sito in locale. Giro W37; il nome «Banco AIMONX» è di Pier (W40,
# 11/11/2026). Si lancia una volta per Mac (lo fa CC).
# ⚠️ Fino al W39 l'icona si chiamava «Sito AIMONX in locale»: se c'è ancora, si toglie,
# perché due icone uguali con due nomi farebbero pensare a due attrezzi.
#
# ⛔ L'icona contiene il percorso di QUESTO repo su QUESTO Mac, e per questo
# non è un file del repo (WD17: nessun percorso di Pier in un file tracciato).
# Il percorso si calcola qui, al momento, e si scrive solo sulla Scrivania.
set -eu
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
ICONA="$HOME/Desktop/Banco AIMONX.command"
VECCHIA="$HOME/Desktop/Sito AIMONX in locale.command"
{
  echo '#!/bin/bash'
  echo '# Banco AIMONX: accende il sito AIMONX su questo Mac. Scritta da scripts/modifica/icona.sh.'
  printf 'exec %q\n' "$REPO/scripts/modifica/accendi.sh"
} > "$ICONA"
chmod +x "$ICONA" "$REPO/scripts/modifica/accendi.sh"
if [ -f "$VECCHIA" ] && grep -q "scripts/modifica/accendi.sh" "$VECCHIA"; then rm -f "$VECCHIA"; echo "Tolta la vecchia icona: $VECCHIA"; fi
echo "Icona scritta: $ICONA"
