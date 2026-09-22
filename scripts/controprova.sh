#!/bin/bash
#
# Controprova di fine giro — il quadro del repo del sito.
# Uso:  scripts/controprova.sh                    quadro completo
#       scripts/controprova.sh --aggiorna-attese  riscrive i valori attesi misurati ora
#
# ⭐ Ricalca scripts/controprova.sh del repo dell'app: stessa struttura, stesse
# regole (attese in un file solo, terzo esito «non misurabile», guardrail dei
# file vivi). ⛔ Cambiano i controlli: qui non c'è codice, c'è un sito.
#
# ⛔ COSA NON COPRE, dichiarato: vedi la sezione finale dell'output.
#
set -u
REPO="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$REPO" || exit 1

ATTESE="$REPO/scripts/attese.txt"

# ⛔ WD17 — i due percorsi fuori dal repo NON stanno qui: questo file è
# tracciato e il repo è PUBBLICO. Stanno in scripts/percorsi-locali.sh, che
# .gitignore tiene fuori, e che definisce PIER_DIR e APP_DIR.
# ⚠️ Senza quel file l'indice esterno non si costruisce: il controllo dei
# puntatori esce «non misurabile» e lo DICE. ⭐ Il terzo esito, non una resa.
PIER_DIR=""
APP_DIR=""
PERCORSI_LOCALI="$REPO/scripts/percorsi-locali.sh"
# shellcheck source=/dev/null
[ -r "$PERCORSI_LOCALI" ] && . "$PERCORSI_LOCALI"
SITO="https://aimonx.app/"

AGGIORNA=0
for arg in "$@"; do
  case "$arg" in
    --aggiorna-attese) AGGIORNA=1 ;;
    *) echo "⛔ opzione sconosciuta: $arg (attesa: --aggiorna-attese)"; exit 2 ;;
  esac
done

# --- sonde degli strumenti ---------------------------------------------------
# ⛔ Uno strumento guasto NON produce un errore visibile in un quadro come
# questo: produce CAMPI VUOTI, e un campo vuoto si legge come un valore.
# ⭐ Si guarda il CODICE DI USCITA, mai il testo.
# Uscita 3: uno strumento non utilizzabile (la 2 è l'opzione sconosciuta).
guasto() {
  {
    echo "⛔ CONTROPROVA FERMATA: $1 è uscito con codice $2."
    echo "   Il quadro si ferma qui: con uno strumento guasto i campi uscirebbero"
    echo "   vuoti, e un campo vuoto si legge come un valore."
    echo "   prime righe di stderr, così come sono:"
    if [ -s "$3" ]; then head -n 10 "$3" | sed 's/^/   │ /'; else echo "   │ (stderr vuoto)"; fi
  } >&2
  rm -f "$3"
  exit 3
}

# esegui VAR COMANDO… → lo stdout del comando in VAR; se esce ≠ 0, guasto.
# ⚠️ Una pipe restituisce il codice dell'ULTIMO comando: qui il comando gira da solo.
esegui() {
  local var="$1" err out rc
  shift
  err=$(mktemp)
  out=$("$@" 2>"$err")
  rc=$?
  [ "$rc" -eq 0 ] || guasto "\`$*\`" "$rc" "$err"
  rm -f "$err"
  printf -v "$var" '%s' "$out"
}

conta_righe() { printf '%s' "$1" | grep -c . | tr -d ' '; }

esegui SONDA git rev-parse --git-dir

MISURE=""
SCOSTAMENTI=0
NON_STABILITE=0

atteso() {
  [ -r "$ATTESE" ] || return 1
  grep -E "^$1=" "$ATTESE" | head -1 | cut -d= -f2-
}

confronta() {
  local et="$1" k="$2" m="$3" a
  MISURE="${MISURE}${k}=${m}
"
  a=$(atteso "$k")
  if [ -z "$a" ]; then
    echo "  $et: misurato $m · atteso NON STABILITO in scripts/attese.txt"
    NON_STABILITE=$((NON_STABILITE + 1))
  elif [ "$a" = "$m" ]; then
    echo "  $et: $m — ✅ combacia"
  else
    echo "  $et: misurato $m · atteso $a — ⛔ NON combacia"
    SCOSTAMENTI=$((SCOSTAMENTI + 1))
  fi
}

aggiorna_attese() {
  local tmp k v vecchio
  tmp=$(mktemp)
  cp "$ATTESE" "$tmp"
  echo
  echo "--- ⚠️  --aggiorna-attese: riscrivo scripts/attese.txt ---"
  while IFS='=' read -r k v; do
    [ -z "$k" ] && continue
    vecchio=$(grep -E "^$k=" "$tmp" | head -1 | cut -d= -f2-)
    if [ "$vecchio" = "$v" ]; then
      echo "  $k: invariato ($v)"
    elif [ -n "$vecchio" ]; then
      echo "  $k: $vecchio → $v"
      awk -v k="$k" -v v="$v" -F= '$1==k {print k "=" v; next} {print}' "$tmp" >"$tmp.new" && mv "$tmp.new" "$tmp"
    else
      echo "  $k: <non stabilito> → $v"
      echo "$k=$v" >>"$tmp"
    fi
  done <<EOF
$MISURE
EOF
  mv "$tmp" "$ATTESE"
  echo "  la modifica è nel working tree: guardala con 'git diff scripts/attese.txt' e committala a mano."
}

echo "=== CONTROPROVA DI FINE GIRO — SITO — $(date '+%Y-%m-%d %H:%M') ==="
echo
echo "--- git ---"
esegui RAMO git branch --show-current
esegui HEAD_CORTO git rev-parse --short HEAD
echo "ramo:    $RAMO @ $HEAD_CORTO"
if git rev-parse --verify -q main >/dev/null; then
  esegui MAIN_CORTO git rev-parse --short main
  echo "main:    $MAIN_CORTO"
else
  echo "main:    ⛔ ASSENTE in locale"
fi
esegui SPORCO git status --porcelain
if [ -z "$SPORCO" ]; then echo "tree:    pulito"; else echo "tree:    SPORCO:"; echo "$SPORCO" | sed 's/^/         /'; fi
esegui STASH_L git stash list
echo "stash:   $(conta_righe "$STASH_L")"
esegui BRANCH_L git branch
esegui TAG_L git tag
esegui REMOTE_L git remote
ORIGIN="nessuno"
if printf '%s\n' "$REMOTE_L" | grep -qx origin; then esegui ORIGIN git remote get-url origin; fi
echo "branch:  $(conta_righe "$BRANCH_L") · tag: $(conta_righe "$TAG_L") · remote: $(conta_righe "$REMOTE_L") ($ORIGIN)"
esegui NON_PUSHATI_L git log --branches --not --remotes --oneline
echo "commit non pushati (tutti i rami): $(conta_righe "$NON_PUSHATI_L")"

# --- cosa pubblicherebbe il merge -------------------------------------------
# ⛔ IL controllo di questo repo, e non ha equivalente in quello dell'app.
# Pages costruisce con Jekyll dalla RADICE di main: ogni .md tracciato che non
# stia sotto una cartella `_` o `.` diventa una PAGINA su aimonx.app.
# ⚠️ Si contano i file TRACCIATI (git ls-files), non quelli sul disco: ciò che
# git non ha non finisce nel merge. E si contano su HEAD, cioè su questo ramo.
#
# ⭐ Il numero non è un allarme: è una domanda. «Questi file, il mondo può
# leggerli?» Se la risposta è no, il merge non si fa — o i file non stanno lì.
echo
# ⚠️ Dal giro W3 questa sezione ha cambiato TEMPO, non misura: il primo merge
# è avvenuto, quindi questi .md sono GIÀ sulla radice di main. La domanda non è
# più «cosa pubblicherebbe un merge» ma «cosa Pages ha sotto mano, e che solo
# `exclude` tiene fuori» — più «cosa aggiungerebbe il prossimo merge», se il
# ramo corrente ne ha di nuovi. ⭐ Il numero risponde a tutte e due, e per
# questo non è cambiato: resta il conto dei CANDIDATI.
echo "--- cosa Pages ha sotto mano su main, e che solo exclude tiene fuori ---"
PAGINE=$(git ls-files '*.md' | grep -vE '(^|/)[_.]' | sort)
N_PAGINE=$(printf '%s' "$PAGINE" | grep -c . | tr -d ' ')
confronta "file .md che diventerebbero pagine" pagine_dal_merge "$N_PAGINE"
if [ "$N_PAGINE" != "0" ]; then
  printf '%s\n' "$PAGINE" | sed -E 's|\.md$|.html|; s|^|     → aimonx.app/|'
fi
echo "  ⚠️ e il repo è PUBBLICO: questi file sono leggibili su github.com già al PUSH,"
echo "     senza aspettare il merge. Vedi WD17 in docs/aperti.md."
echo "  ⭐ Che exclude li tenga fuori NON è più solo una prova locale: dal giro W3"
echo "     è misurato sul mondo — aimonx.app/CLAUDE.html risponde 404."
# ⛔ Il numero qui sopra conta i CANDIDATI, non le pagine vere: questo script non
# esegue Jekyll e non applica `exclude`. ⚠️ Tenerlo così è voluto — è l'allarme
# che suona quando entra un file .md nuovo, ed è l'unica cosa che `exclude`,
# essendo una lista di negazioni, non può fare da sé.
if [ -f "$REPO/_config.yml" ] && grep -q '^exclude:' "$REPO/_config.yml"; then
  echo "  ⚠️ _config.yml ne esclude una parte (WD19), e ⭐ ORA SI PROVA: vedi qui sotto."
fi

# --- WD25: l'esclusione si PROVA costruendo --------------------------------
# ⛔ Fino al giro W2 questo era il buco del repo: `exclude` dichiarava di
# tenere fuori i file di lavoro, e nessuno l'aveva mai visto fare. ⚠️ Una
# lista di negazioni FALLISCE APERTA, quindi «dichiarato» e «vero» qui non
# sono la stessa cosa, e la differenza la legge il mondo.
#
# ⭐ Qui Jekyll gira davvero, con le versioni di GitHub Pages (Gemfile), e si
# guarda il RISULTATO invece della configurazione. Si costruisce in una
# cartella temporanea: il quadro non deve lasciare artefatti nel repo.
#
# ⛔ La lista dei motivi NON è scritta a mano: si legge da `exclude` di
# _config.yml. Chi aggiunge una voce lì è coperto da sé, e un controllo che
# ripete a mano una lista diverge dalla lista il giorno dopo.
#
# ⚠️ Se la toolchain non c'è (un Mac nuovo, un clone fresco), l'esito è
# «NON MISURABILE» e lo dice: ⭐ il terzo esito, non una soglia più larga.
echo
echo "--- WD25: esclusione PROVATA costruendo (Jekyll, versioni di Pages) ---"
RUBY_BIN="$HOME/.rbenv/versions/3.3.4/bin"
if [ ! -x "$RUBY_BIN/bundle" ] || [ ! -d "$REPO/vendor/bundle" ]; then
  echo "  ⛔ NON MISURABILE: la toolchain Jekyll locale manca su questo Mac."
  echo "     Si rifà con i comandi in CLAUDE.md, sezione «Comandi». Senza, la"
  echo "     prova di WD25 non esiste e `exclude` resta una dichiarazione."
else
  SITO_TMP=$(mktemp -d)
  BUILD_ERR=$(mktemp)
  # ⛔ `--safe` non è un di più: è come costruisce Pages, e in safe mode Jekyll
  # NON legge il remote git. ⚠️ Niente PAGES_REPO_NWO qui, apposta: il nome del
  # repo sta in `repository:` dentro _config.yml, e passarlo anche da qui
  # nasconderebbe il giorno in cui quella riga sparisce.
  if PATH="$RUBY_BIN:$PATH" JEKYLL_ENV=production \
     "$RUBY_BIN/bundle" exec jekyll build --safe -d "$SITO_TMP" >/dev/null 2>"$BUILD_ERR"; then
    # I motivi arrivano da `exclude`. ⚠️ La / finale si toglie: in _site un
    # `docs/` escluso si cercherebbe come `docs/qualcosa`, non come `docs/`.
    N_TROVATI=0
    TROVATI=""
    while read -r VOCE; do
      [ -n "$VOCE" ] || continue
      VOCE="${VOCE%/}"
      # ⛔ -maxdepth non va bene: un file escluso può ricomparire annidato.
      TROVA=$(cd "$SITO_TMP" && find . -name "$(basename "$VOCE")" 2>/dev/null)
      if [ -n "$TROVA" ]; then
        N_TROVATI=$((N_TROVATI + $(printf '%s' "$TROVA" | grep -c .)))
        TROVATI="$TROVATI$VOCE -> $TROVA
"
      fi
    done <<VOCI
$("$RUBY_BIN/ruby" -ryaml -e 'puts(YAML.load_file("_config.yml")["exclude"] || [])' 2>/dev/null)
VOCI
    confronta "file di lavoro finiti nel sito costruito" file_lavoro_pubblicati "$N_TROVATI"
    if [ "$N_TROVATI" != "0" ]; then
      printf '%s' "$TROVATI" | sed 's/^/     ⛔ /'
      echo "     ⛔ `exclude` NON TIENE. Un merge li metterebbe su aimonx.app."
    fi

    # ⛔ WD23 — lo schema che la pagina dichiara di sé. Non è «Enforce HTTPS»,
    # che è GitHub a fare: questo lo scrive Jekyll, e senza `url` in
    # _config.yml indovina `http://`. ⚠️ Si misura sulla BUILD; cosa legga il
    # mondo lo dice `curl`, e fra i due c'è il merge.
    N_HTTP=$(grep -rohE 'http://[a-z0-9.-]*aimonx\.app' "$SITO_TMP" 2>/dev/null | grep -c . | tr -d ' ')
    confronta "\"http://aimonx.app\" nel sito costruito" http_nella_build "$N_HTTP"

    # ⛔ Vincolo del sito: nessuna risorsa da server esterni (CLAUDE.md).
    # Un font o uno script caricato da fuori dice a quel server chi visita
    # aimonx.app — su un sito che vende privacy è una contraddizione pubblica.
    #
    # ⛔⛔ CORRETTO NEL GIRO W9, e la vecchia riga era SBAGLIATA: contava ogni
    # `href="https://…"`, quindi anche gli `<a>`. ⚠️ Un LINK VERSO FUORI NON È
    # UNA RISORSA ESTERNA — la pagina non scarica niente da quel dominio, ci
    # manda il lettore solo se clicca, e finché non clicca quel server non sa
    # che esiste. Confonderli avrebbe fatto due danni in un colpo: la Privacy
    # Policy, che DEVE poter citare l'informativa di GitHub e quella di Apple,
    # avrebbe fatto protestare il controllo; e per farlo tacere qualcuno
    # avrebbe alzato l'attesa da 0 a 4 — cioè avrebbe spento, per far passare
    # quattro link, il controllo che tiene fuori i font e gli script altrui.
    # ⭐ Così invece i link si CONTANO A PARTE, e si guardano.
    #
    # ⚠️ Questo conta i riferimenti SCRITTI nell'HTML. Quel che il browser
    # chiede DAVVERO lo dice scripts/anteprima-playwright.mjs, ed è un'altra
    # misura: un `<script>` può aggiungerne altri a pagina aperta.
    RISORSE=$("$RUBY_BIN/ruby" -e '
      fuori = []
      Dir.glob(File.join(ARGV[0], "**", "*.{html,css,js}")).sort.each do |f|
        t = File.read(f, encoding: "UTF-8").gsub(/<!--.*?-->/m, " ")
        # ⛔ Si saltano i tag <a>: sono link, non risorse. Tutto il resto che
        # porta un src= o un href= (link rel, img, script, iframe...) carica.
        t.gsub(/<a\b[^>]*>/i, " ").scan(/\b(?:src|href)="(https?:\/\/[^"]+)"/) { |(u)| fuori << u }
        # E il CSS, che carica con url(...) e non con un attributo.
        t.scan(/url\(\s*["\x27]?(https?:\/\/[^)"\x27]+)/) { |(u)| fuori << u }
      end
      fuori.reject! { |u| u =~ %r{\A https?://([a-z0-9-]+\.)? aimonx\.app}x }
      puts fuori.uniq
    ' "$SITO_TMP" 2>/dev/null)
    N_EST=$(printf '%s' "$RISORSE" | grep -c . | tr -d ' ')
    confronta "risorse da domini esterni nel sito costruito" risorse_esterne_build "$N_EST"
    if [ "$N_EST" != "0" ]; then
      printf '%s\n' "$RISORSE" | sed 's/^/     ⚠️ /'
      echo "     ⚠️ Vedi WD26 in docs/aperti.md."
    fi

    # --- le misure sulle PAGINE costruite (giro W9) ---------------------------
    # ⛔ Quattro numeri, e uno è il MUST di Pier misurato invece che riletto.
    # Il programma sta in scripts/misure-pagine.rb, con le sue ragioni.
    echo
    echo "--- le quattro pagine, guardate una per una (giro W9) ---"
    # ⛔ La variabile NON si chiama MISURE, e non è un vezzo: `MISURE` è la
    # variabile globale in cui `confronta` accumula le coppie chiave=valore che
    # `--aggiorna-attese` poi riscrive. Chiamarla così qui la sovrascriveva, e
    # il baseline si sarebbe riallineato su quattro righe invece che su tutte.
    # ⚠️ Misurato nel giro W9: l'errore si è visto perché l'uscita usciva
    # appiccicata, non perché qualcuno l'avesse previsto.
    PAGINE_OUT=$("$RUBY_BIN/ruby" "$REPO/scripts/misure-pagine.rb" "$SITO_TMP" 2>&1)
    for CHIAVE in pagine_costruite link_rotti titoli_fuori_ordine indirizzi_o_telefoni; do
      VALORE=$(printf '%s\n' "$PAGINE_OUT" | sed -n "s/^$CHIAVE=\([0-9]*\)$/\1/p" | head -1)
      [ -n "$VALORE" ] && confronta "$CHIAVE" "$CHIAVE" "$VALORE"
    done
    printf '%s\n' "$PAGINE_OUT" | grep -E '^  ' | sed 's/^/   /'
    N_FUORI_LINK=$(printf '%s\n' "$PAGINE_OUT" | sed -n 's/^link_verso_fuori=\([0-9]*\)$/\1/p' | head -1)
    echo "  ⚠️ link verso l'esterno: $N_FUORI_LINK — NON sono risorse esterne (vedi sopra),"
    echo "     e non hanno un'attesa: cambiano quando il testo approvato cita un altro sito."

    # --- ② il testo SERVITO, non solo quello nei file di dati -----------------
    # ⛔ Non è un doppione del controllo più in basso: quello guarda i file di
    # dati, questo guarda quel che esce. Una frase scritta in un LAYOUT non sta
    # in nessun file di dati, e solo questa misura la vede. Provato nel W9
    # mettendone una a mano: la misura sui dati non si accorge di niente.
    echo
    echo "--- il testo SERVITO viene tutto da una bozza approvata? ---"
    USCITA_SERVITO=$("$REPO/scripts/testo-approvato.sh" --servito "$SITO_TMP" 2>&1)
    printf '%s\n' "$USCITA_SERVITO"
    N_SERV=$(printf '%s' "$USCITA_SERVITO" | sed -n 's/.*fuori_bozza=\([0-9]*\).*/\1/p' | head -1)
    [ -n "$N_SERV" ] && confronta "pezzi di testo servito non approvati" testo_servito_fuori_bozza "$N_SERV"
  else
    # ⛔ Una build fallita NON è «zero file di lavoro»: è una misura che non
    # c'è stata. Dirla ✅ sarebbe il via libera che non ha guardato niente.
    echo "  ⛔ NON MISURABILE: la build Jekyll è fallita. Prime righe di stderr:"
    head -n 6 "$BUILD_ERR" | sed 's/^/     │ /'
  fi
  rm -rf "$SITO_TMP" "$BUILD_ERR"
fi

# --- WD17: il disco di Pier non entra nei file tracciati ---------------------
# Deciso da Pier il 21/09/2026: il repo resta pubblico, ma dai file tracciati
# escono i percorsi delle sue cartelle. Questo controllo è ciò che lo tiene
# vero DOPO il giro che l'ha fatto — senza, regge finché qualcuno se ne ricorda.
#
# ⛔ Il motivo di ricerca si COSTRUISCE, non si scrive: un controllo che
# contenesse i percorsi vietati li pubblicherebbe lui stesso, e si troverebbe.
#   · sempre: la radice delle home di macOS seguita da un nome — cioè
#     qualunque percorso assoluto dentro la cartella di un utente;
#     ⚠️ scritto con una classe di caratteri APPOSTA, così il motivo non
#     trova sé stesso e questo file non risulta sporco mentendo;
#   · in più, se scripts/percorsi-locali.sh c'è: il nome della cartella di Pier,
#     ricavato da PIER_DIR. ⚠️ Senza quel file il controllo è più LARGO, non
#     assente, e la riga qui sotto lo dichiara invece di lasciarlo credere.
VIETATI='/User[s]/'
LARGHEZZA="solo percorsi assoluti"
if [ -n "$PIER_DIR" ]; then
  NOME_CARTELLA=$(basename "$(dirname "$PIER_DIR")")
  VIETATI="$VIETATI|$NOME_CARTELLA"
  LARGHEZZA="percorsi assoluti + il nome della cartella di Pier"
fi
echo
echo "--- WD17: percorsi del disco di Pier nei file tracciati ---"
FILE_SPORCHI=$(git grep -lE "$VIETATI" -- . 2>/dev/null || true)
N_SPORCHI=$(printf '%s' "$FILE_SPORCHI" | grep -c . | tr -d ' ')
confronta "file tracciati che citano un percorso del disco" percorsi_pier "$N_SPORCHI"
echo "  (motivo cercato: $LARGHEZZA)"
if [ "$N_SPORCHI" != "0" ]; then
  printf '%s\n' "$FILE_SPORCHI" | sed 's|^|     ⛔ |'
  echo "     ⛔ Questi file sono leggibili da chiunque al primo push. Vedi WD17."
fi

# --- guardrail dei file vivi -------------------------------------------------
# ⛔ È l'unica cosa che impedisce di ricascare nel monolite IN SILENZIO.
# I tre file vivi del repo. ⚠️ memory.md e spec-sito.md non sono in lista: stanno
# nella cartella di Pier, li scrive Cowork, e un tetto lì misurerebbe lei.
FILE_VIVI="CLAUDE.md docs/aperti.md docs/piano-chiusura.md"

chiave_tetto() { echo "tetto_righe_$(echo "$1" | tr './-' '___')"; }

# ⛔ Il tetto sale solo se il file ha sfondato, e non scende MAI da sé: un tetto
# che si riabbassa sulla misura di oggi non è un tetto, è uno specchio.
proponi_tetto() {
  local m="$1" c="$2"
  if [ -n "$c" ] && [ "$m" -le "$c" ]; then echo "$c"; return; fi
  echo $(( ((m * 115 / 100) / 10 + 1) * 10 ))
}

echo
echo "--- guardrail dei file vivi ---"
for F_VIVO in $FILE_VIVI; do
  if [ ! -r "$F_VIVO" ]; then
    echo "  $F_VIVO: ⛔ ASSENTE o illeggibile — un file vivo che sparisce è uno scostamento"
    SCOSTAMENTI=$((SCOSTAMENTI + 1))
    continue
  fi
  K_TETTO=$(chiave_tetto "$F_VIVO")
  M_RIGHE=$(wc -l <"$F_VIVO" | tr -d ' ')
  T_ATTESO=$(atteso "$K_TETTO")
  MISURE="${MISURE}${K_TETTO}=$(proponi_tetto "$M_RIGHE" "$T_ATTESO")
"
  if [ -z "$T_ATTESO" ]; then
    echo "  $F_VIVO: $M_RIGHE righe · tetto NON STABILITO in scripts/attese.txt"
    NON_STABILITE=$((NON_STABILITE + 1))
  elif [ "$M_RIGHE" -le "$T_ATTESO" ]; then
    echo "  $F_VIVO: $M_RIGHE righe / tetto $T_ATTESO — ✅ sotto il tetto"
  else
    echo "  $F_VIVO: $M_RIGHE righe / tetto $T_ATTESO — ⛔ TETTO SFONDATO: il file sta ingrassando"
    SCOSTAMENTI=$((SCOSTAMENTI + 1))
  fi
done

# ⛔ Il vero cane da guardia: una data in un titolo di un file vivo vuol dire che
# un VERBALE è entrato dove non doveva. ⚠️ Solo i titoli di primo livello (^## ):
# la regola larga fa falsi positivi su date di registro dentro una tabella.
RE_DATA='[0-9]{1,2}/[0-9]{1,2}/20[0-9]{2}|20[0-9]{2}-[0-9]{2}-[0-9]{2}'
DATATI=$(grep -hE '^## ' $FILE_VIVI 2>/dev/null | grep -cE "$RE_DATA" | tr -d ' ')
confronta "titoli ## datati nei file vivi" titoli_datati "$DATATI"
if [ "$DATATI" != "0" ]; then
  grep -hE '^## ' $FILE_VIVI 2>/dev/null | grep -E "$RE_DATA" | sed 's/^/     ⛔ /'
fi

# --- puntatori rotti nei file vivi -------------------------------------------
# ⛔ NON prende le frasi false: nessuno script può. Prende la famiglia dei
# PUNTATORI ROTTI — un percorso citato che sul disco non esiste.
#
# ⭐ E prende anche il verso opposto, che nell'app non serviva e qui sì: un
# percorso citato con **⏳ subito prima del backtick** è una PROMESSA («questa
# cartella nasce dopo»), non un puntatore rotto. Il controllo utile non è «la
# promessa non risolve» — è ovvio — ma ⛔ «la promessa ORA RISOLVE e il ⏳ è
# rimasto lì»: un file vivo che annuncia come futuro qualcosa che esiste già
# dice il falso, e nessuno se ne accorge rileggendo.
#
# ⛔ Il marcatore sta sulla CITAZIONE, non sulla riga, e non è un dettaglio: in
# docs/aperti.md ogni riga di una voce aperta contiene un ⏳ nella colonna
# «Stato», e un ⏳ per riga dichiarerebbe futuri tutti i percorsi di quella
# riga — misurato: dodici indirizzi veri classificati come promesse.
#
# Regole di estrazione, e ciascuna toglie una famiglia di falsi positivi
# MISURATA su questi tre file, non immaginata:
#   · solo ciò che sta fra backtick;
#   · ⛔ le porzioni ~~barrate~~ si tolgono PRIMA: una voce chiusa cita apposta
#     il percorso di PRIMA, e la storia non si ripara;
#   · ⚠️ la / finale si toglie PRIMA del filtro, se no `aggiornamenti/` passa
#     per indirizzo ed è un nome nudo;
#   · ⚠️ solo i token con una `/`: un nome nudo è un NOME, non un indirizzo;
#   · ⛔ fuori le RIGHE DI COMANDO, che di slash ne hanno quante un percorso:
#     `gh api repos/aimonxapp/aimonx/pages` non è una cartella. Si riconoscono
#     dalla prima parola, non dalla forma;
#   · ⛔ fuori i DOMINI: `aimonx.app/docs/aperti.html` è un indirizzo del web,
#     e questo script guarda il disco. ⚠️ Con i SOTTODOMINI, misurato nel giro
#     W2: il motivo accettava una sola etichetta prima del dominio di primo
#     livello, e `pages.github.com/versions.json` — la fonte delle versioni di
#     Pages, citata in due file vivi — usciva «rotto». Un guardrail che
#     protesta su una citazione giusta è il primo passo verso lo spegnerlo;
#   · ⛔ fuori le IDENTITÀ REMOTE (`aimonxapp/aimonx`): somigliano a un percorso
#     e non lo sono;
#   · ⚠️ fuori i segnaposto e le intestazioni HTTP.
#
# ⛔ DUE INDICI, non uno, e li sceglie il PRIMO SEGMENTO del token. Se è un
# nome che esiste alla radice di questo repo (`docs`, `scripts`, `.claude`…),
# l'indirizzo è di casa e ⛔ si risolve SOLO nel repo; tutto il resto si cerca
# fuori. Misurato perché un indice unico mente: `docs/aperti-chiusi.md` — che
# qui non esiste — risolveva sul file omonimo del repo dell'app, e il controllo
# diceva ✅. ⭐ La lista dei nomi di casa si misura, non si scrive a mano: un
# file nuovo alla radice entra da sé.
#
# La risoluzione è PER SUFFISSO su percorsi assoluti: un file SPOSTATO non ha
# più nessun percorso reale che finisca per il vecchio indirizzo, e scatta.
# ⚠️ Il confronto IGNORA maiuscole e minuscole, perché il filesystem le ignora:
# su APFS `~/Developer/aimonx` apre `~/Developer/AIMONX`, e un confronto
# sensibile al caso direbbe «rotto» di un indirizzo che il Mac risolve.
# ⚠️ I nomi si confrontano in NFC: il filesystem di macOS conserva gli accenti
# in NFD, i file .md li scrivono in NFC.
# ⚠️ PIER_DIR e APP_DIR sono definiti in cima al file: servono anche al
# controllo WD17, che viene molto prima di qui.
# ⚠️ Non sono percorsi: identità remote che assomigliano a un percorso.
NON_PERCORSI='aimonxapp/aimonx Pier974/AIMONX Pier974/GRDB.swift'

echo
echo "--- puntatori rotti nei file vivi ---"
IDX_REPO=$(mktemp)
IDX_FUORI=$(mktemp)
find "$REPO" -path '*/.git' -prune -o -print 2>/dev/null >"$IDX_REPO"
FUORI_LEGGIBILE=1
for D in "$PIER_DIR" "$APP_DIR"; do
  if [ -r "$D" ]; then
    find "$D" -path '*/.git' -prune -o -print 2>/dev/null >>"$IDX_FUORI"
  else
    FUORI_LEGGIBILE=0
  fi
done
# ⚠️ ~/Developer si indicizza a UN livello e non di più: i due repo di terze
# parti che ci stanno accanto sono decine di migliaia di file, e nessun file
# vivo di questo repo li cita. Serve a risolvere `~/Developer/<qualcosa>`.
find "$(dirname "$REPO")" -maxdepth 1 -print 2>/dev/null >>"$IDX_FUORI"
for F in "$IDX_REPO" "$IDX_FUORI"; do
  perl -MUnicode::Normalize -CSD -ne 'print NFC($_)' <"$F" >"$F.nfc" && mv "$F.nfc" "$F"
done

# estrai — stdin = un file vivo; stdout = righe "ORA<TAB>indirizzo" o "POI<TAB>…".
estrai() {
  sed -E 's/~~[^~]*~~//g' | perl -CSD -ne '
    while (/(\x{23F3}\s*)?`([^`]+)`/g) {
      my ($poi, $t) = ($1, $2);
      $t =~ s/:\d+(-\d+)?$//;  $t =~ s/[.,;)]+$//;
      $t =~ s{^\x{2026}/}{};   $t =~ s{^~/}{};   $t =~ s{/+$}{};
      next unless $t =~ m{/};
      next if $t =~ m{^/};
      next if $t =~ /[*|\@\x{2026}\$><()"?=]/;
      next if $t =~ / -/ || $t =~ m{ / };
      next if $t =~ /^(gh|git|curl|find|rm|ls|bash|sed|awk|grep|xargs|wc|chmod)\s/;
      next if $t =~ m{^HTTP/} || $t =~ m{https?:};
      next if $t =~ /^[a-z0-9-]+(\.[a-z0-9-]+)*\.(app|com|io|org|net|dev)(\/|$)/;
      print(($poi ? "POI" : "ORA"), "\t", $t, "\n");
    }' | perl -MUnicode::Normalize -CSD -ne 'print NFC($_)' | sort -u
}

CANDIDATI=$(mktemp)
for F_VIVO in $FILE_VIVI; do
  [ -r "$F_VIVO" ] || continue
  estrai <"$F_VIVO" | sed "s|^|$F_VIVO\t|" >>"$CANDIDATI"
done

# risolve INDIRIZZO → 0 se esiste. L'indice lo sceglie la forma del token.
# I nomi alla radice del repo: misurati, non scritti a mano.
RADICE_REPO=$(cd "$REPO" && ls -A | tr '\n' ' ')
risolve() {
  local t="$1" primo idx="$IDX_FUORI"
  primo="${t%%/*}"
  case " $RADICE_REPO " in *" $primo "*) idx="$IDX_REPO" ;; esac
  grep -qixF "$t" "$idx" && return 0
  grep -qiF "/$t" "$idx" && return 0
  return 1
}
escluso() { case " $NON_PERCORSI " in *" $1 "*) return 0 ;; esac; return 1; }

ROTTI=$(mktemp); SCADUTE=$(mktemp)
N_ORA=0; N_POI=0
while IFS=$(printf '\t') read -r F_SRC QUANDO P_CIT; do
  [ -n "${P_CIT:-}" ] || continue
  escluso "$P_CIT" && continue
  if [ "$QUANDO" = "POI" ]; then
    N_POI=$((N_POI + 1))
    risolve "$P_CIT" && printf '%s: %s\n' "$F_SRC" "$P_CIT" >>"$SCADUTE"
  else
    N_ORA=$((N_ORA + 1))
    risolve "$P_CIT" || printf '%s: %s\n' "$F_SRC" "$P_CIT" >>"$ROTTI"
  fi
done <"$CANDIDATI"

N_ROTTI=$(grep -c . "$ROTTI" | tr -d ' ')
N_SCADUTE=$(grep -c . "$SCADUTE" | tr -d ' ')
if [ "$FUORI_LEGGIBILE" = 1 ]; then
  confronta "percorsi citati che non esistono" percorsi_rotti "$N_ROTTI"
  confronta "promesse ⏳ che ormai esistono"   promesse_scadute "$N_SCADUTE"
else
  # ⚠️ Dichiarato invece di finto: senza la cartella di Pier o il repo dell'app
  # metà degli indirizzi non ha modo di risolvere, e un numero misurato così
  # direbbe «rotto» di roba sana. ⭐ Il terzo esito, non una soglia più larga.
  echo "  percorsi citati: ⛔ NON MISURABILI — la cartella di Pier o il repo dell'app"
  echo "     non sono leggibili. ⛔ I due percorsi non si stampano (WD17): li"
  echo "     definisce scripts/percorsi-locali.sh, e senza quel file è questo l'esito."
fi
echo "  ($N_ORA indirizzi da risolvere ora · $N_POI marcati ⏳; i nomi nudi non si controllano)"
if [ "$FUORI_LEGGIBILE" = 1 ]; then
  [ "$N_ROTTI"   != "0" ] && sed 's/^/     ⛔ rotto: /' "$ROTTI"
  [ "$N_SCADUTE" != "0" ] && sed 's/^/     ⛔ ⏳ scaduto, esiste già: /' "$SCADUTE"
fi
rm -f "$IDX_REPO" "$IDX_FUORI" "$CANDIDATI" "$ROTTI" "$SCADUTE"

# --- tracker nell'HTML -------------------------------------------------------
# ⛔ Vincolo non negoziabile: nessun tracker, nessun analytics (spec-sito.md §6).
# ⚠️ Oggi l'HTML nel repo NON ESISTE, e un controllo che misura il vuoto
# direbbe «✅ zero tracker» su zero file: è un via libera che non ha guardato
# niente. ⭐ Terzo esito, e diventa una misura vera il giorno in cui l'HTML c'è.
echo
echo "--- tracker nell'HTML del repo ---"
HTML=$(git ls-files '*.html' '*.js')
N_HTML=$(printf '%s' "$HTML" | grep -c . | tr -d ' ')
if [ "$N_HTML" = "0" ]; then
  echo "  ⛔ NON MISURABILE: 0 file .html/.js tracciati nel repo — non c'è nulla da guardare."
  echo "     Diventa una misura vera quando il sito avrà pagine (WD19, poi WA4)."
else
  DOMINI='google-analytics|googletagmanager|gtag\(|facebook\.net|hotjar|mixpanel|segment\.(io|com)|plausible|matomo|clarity\.ms|doubleclick'
  N_TRACKER=$(git ls-files '*.html' '*.js' -z | xargs -0 grep -lEi "$DOMINI" 2>/dev/null | wc -l | tr -d ' ')
  confronta "file con un dominio di tracker" file_con_tracker "$N_TRACKER"
  [ "$N_TRACKER" != "0" ] && git ls-files '*.html' '*.js' -z | xargs -0 grep -lEi "$DOMINI" | sed 's/^/     ⛔ /'
fi

# --- il testo in pagina è quello approvato? --------------------------------
# ⛔ NON dice se un testo è buono: quello resta «l'unica zona senza controprova
# meccanica» (CLAUDE.md). Dice se è QUELLO — cioè se qualcuno ha riscritto nel
# repo una frase che l'utente legge, che è un lavoro di Cowork.
# ⚠️ Scatta anche quando cambia la BOZZA: lì non c'è un errore da riparare, c'è
# una consegna nuova da portare nei file di _data/.
echo
echo "--- il testo delle quattro pagine è quello approvato da Pier? ---"
USCITA_TESTO=$("$REPO/scripts/testo-approvato.sh" 2>&1)
printf '%s\n' "$USCITA_TESTO"
N_FUORI=$(printf '%s' "$USCITA_TESTO" | sed -n 's/.*fuori_bozza=\([0-9]*\).*/\1/p' | head -1)
if [ -n "$N_FUORI" ]; then
  confronta "stringhe in pagina che NON stanno nella bozza" testo_fuori_bozza "$N_FUORI"
fi

echo
echo "--- esito dei confronti ---"
if [ ! -r "$ATTESE" ]; then
  echo "⛔ scripts/attese.txt non leggibile: senza attese non c'è controprova."
elif [ "$SCOSTAMENTI" -gt 0 ]; then
  echo "⛔ $SCOSTAMENTI valore/i NON combacia/no — fermarsi e riferire."
  echo "   Se lo scostamento è voluto, il baseline si sposta a mano: --aggiorna-attese."
elif [ "$NON_STABILITE" -gt 0 ]; then
  echo "⚠️  tutto ciò che era stabilito combacia, ma $NON_STABILITE valore/i non è mai stato stabilito."
else
  echo "✅ tutti i valori misurati in questa run combaciano con scripts/attese.txt."
fi

[ "$AGGIORNA" = 1 ] && aggiorna_attese

echo
echo "=== NON AUTOMATIZZABILE, e dichiarato ==="
echo "· cosa il MONDO legge davvero: lo dice 'curl -sSI $SITO', non questo script."
echo "  Fra il repo e il sito c'è la build di Pages, che qui non gira"
echo "· se un testo è chiaro, e se il tono è sportivo invece che militare"
echo "· se una pagina promette una funzione che l'app non ha: si verifica a mano"
echo "  contro ~/Developer/AIMONX/docs/prodotto.md, non contro spec-sito.md"
echo "· il CONTRASTO del testo e le richieste verso l'esterno col browser vero:"
echo "  si misurano, ma servono le pagine ACCESE — 'bundle exec jekyll serve' e poi"
echo "  scripts/contrasto.mjs, scripts/sbordi.mjs e scripts/anteprima-playwright.mjs."
echo "  ⛔ Non si agganciano qui: un controllo che quasi sempre dice 'non misurabile'"
echo "  smette di essere letto, ed è così che muoiono i guardrail"
echo "· il confronto AL BYTE fra questa build e quella di Pages: si fa dopo il"
echo "  merge, con il sito vero in mano (WD31), e non da qui"
