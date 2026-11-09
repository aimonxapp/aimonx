#!/bin/bash
#
# scripts/modifica/accendi.sh — ACCENDE IL SITO IN LOCALE per Pier. Giro W37.
# Lo lancia l'icona sulla Scrivania (la scrive `scripts/modifica/icona.sh`);
# si spegne chiudendo la finestra del Terminale che apre.
#
# ⭐ IL RAMO: le modifiche di Pier non stanno MAI su `main`. Se il ramo di adesso
# non è già un `modifiche-pier-…`, se ne apre uno nuovo dal punto in cui si è
# (dopo la pubblicazione del W37 sarà `main`). ⛔ Se però c'è lavoro di CC non
# salvato, non si cambia ramo e non si accende: si dice di chiedere a CC.
# ⛔ NON SALVA IN GIT: l'attrezzo scrive i file e basta. Il commit lo fa CC
# quando Pier dice «ho finito» — e così l'hook che spinge il ramo sul repo
# PUBBLICO non porta online bozze non ancora approvate.
#
# ⛔ NON VA MAI ONLINE: sta sotto `scripts/`, che `_config.yml` esclude.
set -u
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO" || exit 1
export PATH="$HOME/.rbenv/versions/3.3.4/bin:$PATH"
PORTA="${MODIFICA_PORTA:-4100}"
INDIRIZZO="http://127.0.0.1:$PORTA/"

fermati() {
  echo
  echo "$1"
  echo
  read -r -p "Premi Invio per chiudere questa finestra. " _
  exit 1
}

clear
echo "AIMONX · il sito su questo Mac"
echo "──────────────────────────────"

# Già acceso? Allora si apre solo il browser.
if curl -s -m 2 "${INDIRIZZO}__modifica/stato" | grep -q '"versione"'; then
  open "$INDIRIZZO"
  echo "Era già acceso: ho aperto il browser. Questa finestra si può chiudere."
  sleep 4
  exit 0
fi

if lsof -nP -iTCP:"$PORTA" -sTCP:LISTEN >/dev/null 2>&1; then
  fermati "⛔ Un altro programma sta usando la porta $PORTA. Chiedi a CC."
fi

RAMO=$(git rev-parse --abbrev-ref HEAD)
case "$RAMO" in
  modifiche-pier-*) ;;
  *)
    if [ -n "$(git status --porcelain)" ]; then
      fermati "⛔ Non accendo: CC ha un lavoro in corso non ancora salvato (ramo $RAMO).
   Chiedi a CC di salvarlo, poi riaccendi."
    fi
    NUOVO="modifiche-pier-$(date +%Y-%m-%d)"
    if git show-ref --verify --quiet "refs/heads/$NUOVO"; then
      NUOVO="$NUOVO-$(date +%H%M)"
    fi
    git switch -q -c "$NUOVO" || fermati "⛔ Non riesco ad aprire il ramo $NUOVO. Chiedi a CC."
    RAMO="$NUOVO"
    ;;
esac

echo "Ramo delle tue modifiche: $RAMO"
echo
echo "⏳ Costruisco il sito… (qualche secondo)"
echo
echo "⛔ NON CHIUDERE questa finestra mentre lavori."
echo "   Per spegnere il sito: chiudi questa finestra"
echo "   (se il Mac chiede conferma, rispondi «Termina»)."
echo

# Il browser si apre appena il sito è pronto.
(
  for _ in $(seq 1 120); do
    if curl -s -m 1 "${INDIRIZZO}__modifica/stato" | grep -q '"costruisce":false'; then
      open "$INDIRIZZO"
      exit 0
    fi
    sleep 1
  done
) &

exec bundle exec ruby scripts/modifica/server.rb "$PORTA"
