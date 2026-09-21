#!/bin/bash
#
# Hook Stop — il push verso aimonxapp/aimonx.
# Push del SOLO ramo corrente e dei tag, MAI --force, mai riscrittura o
# cancellazione sul remoto. ⛔ Mai `main`: vedi il perché più sotto.
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

# ⛔ SOLO IL RAMO CORRENTE, mai `--all`. Misurato nel giro W1: `--all` avrebbe
# pushato anche `main`, e `main` È IL SITO PUBBLICATO — Pages costruisce dalla
# sua radice. Un hook che parte da sé a ogni Stop non può avere in mano il ramo
# che pubblica al mondo: la pubblicazione la decide Pier, non un automatismo.
RAMO=$(git -C "$REPO" rev-parse --abbrev-ref HEAD 2>/dev/null)

if [ "$RAMO" = "main" ] || [ "$RAMO" = "HEAD" ]; then
  jq -n --arg m "⛔ PUSH NON ESEGUITO: il ramo corrente è \`$RAMO\`.
Su \`main\` il push è una PUBBLICAZIONE (Pages costruisce dalla radice di main),
e non la fa un hook: la autorizza Pier, a mano. Vedi «Regole di ramo» in CLAUDE.md." '{systemMessage:$m}'
  exit 0
fi

ESITO_RAMI=$(git -C "$REPO" push origin "$RAMO" 2>&1)
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
  jq -n --arg m "⛔ PUSH FALLITO verso origin (ramo $RAMO rc=$RC_RAMI, tag rc=$RC_TAG). Il repo locale e il remoto NON sono allineati.
--- rami ---
$ESITO_RAMI
--- tag ---
$ESITO_TAG$NOTA" '{systemMessage:$m}'
fi

exit 0
