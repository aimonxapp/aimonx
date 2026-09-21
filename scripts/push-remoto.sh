#!/bin/bash
#
# Hook Stop — il push verso aimonxapp/aimonx.
# Push di rami e tag, MAI --force, mai riscrittura o cancellazione sul remoto.
# Se il push fallisce lo RIFERISCE in modo visibile; non blocca mai la sessione.
#
# ⚠️ Ricalcato da scripts/push-remoto.sh del repo dell'app, con due differenze:
#   · il remote è un altro (`aimonxapp/aimonx`, non `Pier974/AIMONX`);
#   · ⛔ QUI IL REPO È PUBBLICO. Un push non è «salvare»: rende i file
#     leggibili da chiunque su github.com, senza aspettare il merge.
#     Vedi WD17 in docs/aperti.md.
#
# ⛔ Oggi il push NON passa: la credenziale sul Mac è di `Pier974`, che su
# questo repo ha push: false (WA15). Il messaggio qui sotto lo dice invece di
# lasciare un errore di git che si legge come un guasto.
#
set -u

REPO="${CLAUDE_PROJECT_DIR:-$(pwd)}"

ESITO_RAMI=$(git -C "$REPO" push origin --all 2>&1)
RC_RAMI=$?
ESITO_TAG=$(git -C "$REPO" push origin --tags 2>&1)
RC_TAG=$?

if [ $RC_RAMI -ne 0 ] || [ $RC_TAG -ne 0 ]; then
  NOTA=""
  case "$ESITO_RAMI" in
    *403*|*"Permission"*|*"denied"*|*"Authentication"*)
      NOTA="
⚠️ Somiglia a WA15 (docs/aperti.md): il repo è di \`aimonxapp\`, la credenziale
   sul Mac è di \`Pier974\`, che qui ha push: false. Non è un guasto di git, e
   ⛔ non si aggira: la sblocca Pier."
      ;;
  esac
  jq -n --arg m "⛔ PUSH FALLITO verso origin (rami rc=$RC_RAMI, tag rc=$RC_TAG). Il repo locale e il remoto NON sono allineati.
--- rami ---
$ESITO_RAMI
--- tag ---
$ESITO_TAG$NOTA" '{systemMessage:$m}'
fi

exit 0
