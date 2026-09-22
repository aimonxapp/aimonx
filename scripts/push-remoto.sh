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
# ⭐ Il push PASSA, dal giro W1: `WA15` è chiusa. L'isolamento è un credential
# helper LOCALE a questo repo (`git config --local
# credential.https://github.com.helper`) che prende il token con
# `gh auth token --user aimonxapp` — quindi ⛔ l'account attivo di `gh` resta
# `Pier974` e i push del repo dell'app continuano a firmarsi con lui.
# ⚠️ Queste righe dicevano il contrario fino al giro W4 (WD32): annunciavano
# un guasto che non c'era più da tre giri, e un commento così fa perdere tempo
# a chi legge lo script per capire perché qualcosa non funziona.
# Misura: `gh api repos/aimonxapp/aimonx/pages/builds/latest --jq .pusher.login`
# → `aimonxapp`.
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
      # ⚠️ WA15 è chiusa dal giro W1 e questo errore non è più «lo stato di
      # oggi»: se torna, è il credential helper LOCALE a questo repo che non
      # sta più dando il token di `aimonxapp`. ⛔ Non si aggira cambiando
      # l'account attivo di `gh`: quello è di `Pier974` e serve al repo
      # dell'app — cambiarlo firmerebbe `aimonxapp` anche i push dell'app.
      NOTA="
⚠️ Il repo è di \`aimonxapp\`, e il token lo dà un credential helper LOCALE a
   questo repo. Cosa guardare, in quest'ordine:
     git config --local --get-all credential.https://github.com.helper
     gh auth token --user aimonxapp >/dev/null && echo 'token ok'
   ⛔ NON si usa \`gh auth switch\`: l'account attivo è \`Pier974\` e serve al
   repo dell'app. Vedi WA15 in docs/aperti.md."
      ;;
  esac
  jq -n --arg m "⛔ PUSH FALLITO verso origin (ramo $RAMO rc=$RC_RAMI, tag rc=$RC_TAG). Il repo locale e il remoto NON sono allineati.
--- rami ---
$ESITO_RAMI
--- tag ---
$ESITO_TAG$NOTA" '{systemMessage:$m}'
fi

exit 0
