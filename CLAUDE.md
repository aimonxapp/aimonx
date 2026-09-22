# CLAUDE.md

## Da dove comincio — l'indice

⛔ **Una domanda, un file. Se una cosa sta in due file, uno dei due è sbagliato.**

⚠️ **Il nome di questa cartella non è il nome del repo, e non è un errore.** Il repo su GitHub si chiama **`aimonx`** (`aimonxapp/aimonx`); la cartella locale si chiama `aimonx-web` perché ⛔ **su APFS non distingue maiuscole da minuscole `~/Developer/aimonx` È `~/Developer/AIMONX`**, cioè il repo dell'app. Misurato: `ls -d ~/Developer/aimonx` risponde col percorso di `~/Developer/AIMONX`, cioè apre il repo dell'app. **Il nome vero si legge da `git remote -v`, sempre.**

### I file vivi — si leggono per sapere dov'è il progetto

| Cerchi… | File |
|---|---|
| **il metodo — come si sta in chat con Pier, chi decide cosa, dove sta l'originale del metodo di costruzione** | `…/13 Armi e Tiro/10- AIMONX AI Common/metodo-aimonx.md` — **fuori dal repo**, comune ai due progetti. ⛔ **Non si ricopia qui: si cita** |
| **gli avvisi fra i progetti** — cosa ha cambiato l'altro, cosa aspetta da noi | `…/10- AIMONX AI Common/bacheca.md` — si legge **a ogni sessione** |
| **da dove comincio, cosa non si deroga, gli attrezzi di QUESTO repo** | **questo file** |
| **dove siamo adesso** | `…/13 Armi e Tiro/8- AIMONX web/1- Specifiche/memory.md` — cartella di Pier, **fuori dal repo** |
| **cosa manca e cosa blocca** | `docs/aperti.md` — ID a prefisso `W`; le voci nate dal registro dell'app citano la gemella (`WA1 ↔ RA1`) |
| **come si è chiusa una voce del registro** | ⏳ `docs/aperti-chiusi.md` — nasce alla prima chiusura, non prima; ⛔ non si legge all'avvio |
| **in che ordine, e cosa aspetta cosa** | `docs/piano-chiusura.md` |
| **cosa deve fare il sito — pagine, contenuti, tono** | `…/8- AIMONX web/1- Specifiche/spec-sito.md` — **fuori dal repo, di Cowork**: è testo che il pubblico legge. ⭐ **Sta bene lì, e questo repo non ne tiene copia:** una copia nel repo sarebbe leggibile da chiunque (vedi «Trappole»), e diverge dall'originale il giorno dopo. Se un giro avrà bisogno di un estratto, si cita il `§`, non si ricopia |
| **quali norme toccano il sito** — Italia, UE, USA | `…/8- AIMONX web/1- Specifiche/conformita-sito.md` — **fuori dal repo, di Cowork.** ⚠️ **Mappa, non parere legale**, e i punti aperti stanno al suo §4 |
| **cosa fa l'app** — l'unica autorità su ciò che il sito può promettere | `~/Developer/AIMONX/docs/prodotto.md` (⛔ **sempre col percorso intero:** scritto nudo si leggerebbe come un file di QUESTO repo, e non c'è) — ⛔ **si legge, non si scrive.** Se non sta lì, sul sito non va |
| **cosa dice l'app, in italiano e nei due inglesi** | `~/Developer/AIMONX/catalogo-testi/catalogo-testi-aimonx.xlsx` — le parole del sito sono quelle dell'app |

### Gli attrezzi

| Cerchi… | Dove |
|---|---|
| **come si conduce un giro** | skill `/giro` → `.claude/skills/giro/SKILL.md` — ⭐ **è una COPIA di quella dell'app, non un collegamento**, perché il master comune ⏳ `…/10- AIMONX AI Common/skills/giro/` **non esiste**: misurato, `find "…/10- AIMONX AI Common"` elenca due file e nessuna cartella `skills`. ⚠️ **Una copia diverge in silenzio:** chi cambia questa skill o quella dell'app lascia una riga in `bacheca.md` |
| **la verifica di fine giro** | `scripts/controprova.sh` · valori attesi in `scripts/attese.txt` |
| **con cosa si costruisce il sito in locale** | `Gemfile` — ⛔ **le versioni NON sono una scelta nostra:** sono quelle che GitHub dichiara in `pages.github.com/versions.json`. Costruire con altre significa provare un sito e pubblicarne un altro. Come si rifà: «Comandi» |
| **come si guarda l'anteprima con un browser vero** | `scripts/anteprima-playwright.mjs` — due screenshot, gli errori in console, e ⛔ **ogni richiesta verso un dominio esterno** · `scripts/contrasto.mjs` — il contrasto di **ogni** testo contro WCAG 2.1 AA, preso dai colori calcolati dal browser e ⛔ **non da una lista scritta a mano**, che diverge dal CSS il giorno dopo · `scripts/sbordi.mjs` — cosa sborda dallo schermo, a **otto larghezze da 360 a 1920** e col nome dell'elemento colpevole · `scripts/tastiera.mjs` — il giro del tasto Tab, e ⛔ **che le voci del menu chiuso NON siano raggiungibili**: un link invisibile ma tabbabile fa sparire il fuoco dove non si vede. ⚠️ Nel giro W10 ha trovato una collisione di classi che a occhio non si vedeva. ⚠️ **Non sono test che passano o falliscono: sono misure**, e il giudizio è di chi legge |
| **se il testo in pagina è ancora quello approvato da Pier** | `scripts/testo-approvato.sh` — ⭐ **dal giro W9 sono DUE misure diverse, non una fatta due volte:** senza argomenti cerca ogni stringa dei quattro file di testo di `_data/` **alla lettera** nella bozza di Cowork; con `--servito <build>` cerca ogni pezzo di testo **che esce dal sito costruito**. ⛔ **La prima non vede una frase scritta in un layout**, perché in nessun file di dati compare — provato mettendone una a mano. ⛔ **Non dicono se un testo è buono**, dicono se è *quello*; e ⚠️ **scattano anche quando cambia la bozza** — lì non c'è un errore da riparare, c'è una consegna nuova da portare nel repo |
| **come il sito si fa trovare** — mappa, robots, dati strutturati, immagine di condivisione | `_config.yml` (`plugins: jekyll-sitemap`, ⭐ **unione e non sostituzione**, al contrario di `exclude`: misurato nel gem, riga 168) · `robots.txt` — ⛔ **permette tutto a tutti, crawler delle AI compresi** (Pier, 22/09/2026), e niente commenti dentro: sono pubblici · `_includes/dati-strutturati.html` — ⛔ solo fatti veri, ⚠️ **niente prezzo né voti, quindi il Rich Results Test di Google segnala due campi mancanti: è ATTESO** · `scripts/immagine-condivisione.mjs` — rifà il PNG 1200×630, parole approvate e colori di `comune.scss` |
| **cosa dicono le pagine costruite** — link rotti, ancore rotte, ordine dei titoli, e ⛔⛔ **il MUST di Pier misurato** | `scripts/misure-pagine.rb`, chiamato dalla controprova sulla build. ⛔ **Cerca la FORMA di un recapito o di un telefono, non il valore:** non sa quale sia l'indirizzo di Pier **e non deve saperlo** — un controllo che lo contenesse lo pubblicherebbe lui stesso, come per i percorsi del disco (WD17) |
| **i percorsi di QUESTO Mac** — e perché non stanno in un file tracciato | `scripts/percorsi-locali.sh` e `.claude/settings.local.json`, tenuti fuori da `.gitignore` (WD17). ⚠️ **Non arrivano col clone:** su un Mac nuovo si riscrivono a mano |
| **cosa Pages pubblica e cosa no** | `_config.yml` — ⛔ **`exclude` è una lista di negazioni, e fallisce APERTA in DUE versi.** ① Verso i file nuovi: chi ne aggiunge uno alla radice lo pubblica, e chi se ne accorge è la controprova (`pagine_dal_merge`), non la memoria. ② ⛔ **Verso chi sta sotto:** misurato nel giro W3, GitHub aggiunge `CNAME` alla lista **solo se** la lista è ancora quella di default di Jekyll — riscriverla ha disattivato quell'esclusione senza dirlo (WD29). **Chi tocca questa lista si porta dietro anche i default di chi ci sta sotto** |
| **il push** | `scripts/push-remoto.sh`, chiamato dall'hook `Stop` — remote misurato: `https://github.com/aimonxapp/aimonx.git`. ⛔ **Nessun hook di pin:** il sito non ha una specifica canonica congelata. ⛔ **Spinge il SOLO ramo corrente e rifiuta `main`**, perché `main` è il sito pubblicato |

### Materiale di riferimento — nella cartella di Pier, fuori dal repo

| Cerchi… | Dove |
|---|---|
| **i contenuti scritti e approvati** | `…/8- AIMONX web/2- Contenuti/` |
| **le risorse grafiche del sito** | `…/8- AIMONX web/4- risorse/` — ⚠️ **esiste ed è VUOTA**: `spec-sito.md` §1 la dà per la destinazione degli asset, e l'unico materiale grafico del sito sta altrove (`WD21`). I colori e le misure decise per l'app: `…/7- App AIMONX/1- Specifiche/tavolozza-aimonx.md` |
| **il materiale marketing** (di luglio, da verificare contro `prodotto.md`) | `…/7- App AIMONX/1- Specifiche/marketing-aimonx.md` · `marketing-strategia-aimonx-budget-50.md` |
| **la misura dell'infrastruttura** — Pages, dominio, certificato, posta | `…/7- App AIMONX/3- note/_archivio/nota-infrastruttura-sito-mail-10-08.md` |
| **le lezioni dell'app** — si aprono quando si scrive un giro | `…/7- App AIMONX/1- Specifiche/lezioni-aimonx.md` |
| **i social** | `…/9- AIMONX social/` — ⏳ vuota |

### Archivi — si aprono solo per ricostruire come si è arrivati a una decisione

| Cerchi… | Dove |
|---|---|
| **prompt e risposte dei giri chiusi** | `…/8- AIMONX web/3- note/_archivio/` — c'è dal verbale del giro W0 |
| **la bozza di luglio della struttura del sito** (ChatGPT, non autorità) | `…/8- AIMONX web/1- Specifiche/da GPT/` |

⭐ **Prima si sposta, poi si corregge. Mai nello stesso giro.** **Spostare** è meccanico e si dimostra coi numeri. **Correggere** è giudizio, e il giudizio può perdere pezzi. ⛔ **Mescolarli è il modo in cui si perdono i pezzi**, perché un errore di giudizio si nasconde dentro quella che sembrava una copia, **e nessuna controprova lo vede.**

⭐ **La regola dei due file.** Ogni giro finisce con due **tipi** di scrittura:

1. **i file vivi che ha cambiato** — sovrascritti, sempre al presente. ⭐ **Possono essere più d'uno**, se il giro lo richiede e restano coerenti fra loro.
2. **un verbale in archivio** — la cronaca, che lì può crescere quanto vuole.

⛔ **Il verbale non entra mai in un file vivo.**
⛔ **Se un giro non ha cambiato nessun file vivo, non ha cambiato lo stato del progetto:** è solo storia.
⛔ **Un giro che produce solo documenti non ne apre un altro:** i suoi finding vanno in `docs/aperti.md` e **aspettano** — il registro esiste perché un finding possa aspettare. ⚠️ **Il segnale non è la fatica, è il rendimento per giro che crolla**, e i documenti sui documenti hanno profondità infinita.
⚠️ **Il verbale è la consegna di fine giro, e la archivia Cowork** in `…/8- AIMONX web/3- note/_archivio/`. **Nel repo non serve niente**, e a Claude Code la scrittura lì è negata dai permessi — la lettura no: si legge, non si tocca.

⚠️ **`memory.md` sta nella cartella di Pier, dove la scrittura ti è negata dai permessi.** Si legge, non si tocca. **Quando un file vivo di Cowork va aggiornato, il testo arriva come nota in `…/8- AIMONX web/3- note/` e lo integri tu.** ⛔ **Il recinto qui copre quattro cartelle, non una:** `7- App AIMONX`, `8- AIMONX web`, `9- AIMONX social`, `10- AIMONX AI Common`.

## Progetto

AIMONX sito — il sito pubblico `aimonx.app` dell'app iOS AIMONX, diario tecnico per tiratori sportivi. **Sito statico su GitHub Pages**, con dominio collegato e certificato valido.

- **Repo:** `aimonxapp/aimonx` — ⛔ **pubblico**, ramo di default `main`, zero tag. ⛔ **I conteggi (commit, rami, file) NON si scrivono qui: cambiano a ogni giro.** Si leggono con `git ls-remote origin` e `gh api repos/aimonxapp/aimonx/commits?sha=main`. Remote: `https://github.com/aimonxapp/aimonx.git`. ⭐ **Il proprietario è l'account `aimonxapp`, NON `Pier974`** che possiede il repo dell'app. *(`gh repo view aimonxapp/aimonx`, `gh api repos/aimonxapp/aimonx`.)*
- **Pages pubblica dal ramo `main`, cartella radice `/`**, con **Jekyll** (`"build_type": "legacy"`); dominio `aimonx.app`, certificato approvato. **`https_enforced` è `true`** e `http://aimonx.app` risponde `301` verso HTTPS. ⭐ **E dal giro W3 la pagina si dichiara `https://` anche da sé** nel proprio `canonical`, perché `url:` in `_config.yml` è online — WD23 ✅. ⚠️ **Erano due cose distinte:** il `301` lo fa GitHub, il `canonical` lo scrive Jekyll. *(`gh api repos/aimonxapp/aimonx/pages`, `curl -sSI http://aimonx.app/`.)*
- **Cosa pubblica oggi:** ⭐ **quattro pagine** — la landing (dal giro W7), **Privacy Policy, Support e Terms of Use (dal giro W9)**. Il foglio di stile è il nostro, il font scritto a mano è servito da noi, e le richieste verso l'esterno sono **zero su tutte e quattro, misurate sul sito vero col browser**. ⭐ **È il set minimo di `spec-sito.md` §9 primo tempo, completo** (`WA1`, `WA2`, `WA3`, `WA4` ✅). ⛔ **Il secondo tempo — pulsante di download, features, guide, FAQ — non è cominciato**, e il download non si accende finché l'app non è sullo store. *(`curl -sS https://aimonx.app/ | grep -E 'title|generator'`.)*
- ⛔ **Con cosa si costruirà — Jekyll, HTML puro, altro — è una decisione di Pier:** CC propone con i costi, non decide. Vincoli da `spec-sito.md` §6: statico, JS minimo, nessun database, nessun CMS, nessun tracker.
- ⛔ **`main` è il sito pubblicato, ed è misurato, non più un'ipotesi:** un merge su `main` **è una pubblicazione al mondo**, perché Pages costruisce dalla radice di `main`. La regola di ramo qui pesa il doppio. ⭐ **Esercitato quattro volte — W3, W7, W8, W9** — ogni volta con l'autorizzazione esplicita di Pier: `main` è sempre avanzato in **fast-forward**, mai un `--force`, mai un ramo cancellato. ⭐ **E ogni volta la build di Pages è risultata IDENTICA AL BYTE a quella locale**, file per file — nel W9, **17 file su 17**. ⚠️ **I tempi di ricostruzione NON si scrivono qui:** cambiano a ogni merge (nel W9, 149,6 s) e si leggono con `gh api repos/aimonxapp/aimonx/pages/builds/latest`.

## Comandi

⭐ **La toolchain Jekyll è sul Mac dal giro W2** (WD25, strada A di Pier): il sito si costruisce e **si guarda** prima del merge. ⛔ **Ruby 3.3.4 sta in `~/.rbenv` e NON è nel `PATH`:** il Ruby di sistema non si tocca, quindi ogni comando se lo porta davanti. ⚠️ **Nessuno di questi arriva col clone** (WD28): su un Mac nuovo si rifà la toolchain.

```bash
scripts/controprova.sh                    # quadro di fine giro — ⭐ costruisce DAVVERO e guarda il risultato
scripts/controprova.sh --aggiorna-attese  # riscrive i valori attesi misurati ora

# costruire e guardare — la riga in testa serve a ogni comando che segue
export PATH="$HOME/.rbenv/versions/3.3.4/bin:$PATH"
JEKYLL_ENV=production bundle exec jekyll build --safe   # il risultato in _site/ (ignorato)
# ⛔ `JEKYLL_ENV=production` non è un di più (WD30): senza, Jekyll resta in `development`,
# il gem github-pages salta `sass: style: compressed` e il CSS esce a 136 KB invece dei
# 76 KB che Pages serve. Con la riga giusta le due build sono identiche AL BYTE.
bundle exec jekyll serve           # anteprima su http://127.0.0.1:4000/ — si spegne con ctrl-c
node scripts/anteprima-playwright.mjs http://127.0.0.1:4000/ ~/Desktop/aimonx-anteprima
# le altre due misure col browser vero — ⛔ ogni pagina si passa per intero.
for M in contrasto sbordi tastiera; do node scripts/$M.mjs http://127.0.0.1:4000/{,privacy-policy/,support/,terms/}; done

gh api repos/aimonxapp/aimonx/pages       # cosa pubblica Pages, e da dove
curl -sSI https://aimonx.app/             # cosa risponde il sito vero

# rifare la toolchain su un Mac nuovo (WD28). ⛔ Misurato: `brew install ruby@3.3` NON va
# bene — aggiorna openssl@3, da cui dipende il python degli script dell'app.
brew install libyaml                                      # formula nuova, non aggiorna nulla
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3) --with-libyaml-dir=$(brew --prefix libyaml)" \
  ~/.rbenv/plugins/ruby-build/bin/ruby-build 3.3.4 ~/.rbenv/versions/3.3.4
bundle config set --local path vendor/bundle && bundle install
npm --prefix ~/.aimonx-web-tools install playwright && \
  npx --prefix ~/.aimonx-web-tools playwright install chromium
```

## Gli strumenti di Claude Code — e quelli scartati, con la ragione

⭐ **Due soli, decisi da Pier il 21/09/2026 e installati con scope `project`**, cioè per questo repo: non per tutto il Mac e ⛔ **non per le sessioni del repo dell'app**, dove resta solo `swift-lsp`. Stanno in `.claude/settings.json`.

- **`frontend-design`** — il sito deve essere **figo**. La tavolozza dell'app (`…/7- App AIMONX/1- Specifiche/tavolozza-aimonx.md`) è la base, **e sul sito si può osare.** ⛔ **Due condizioni, e non sono negoziabili con l'estetica:** ① **nessuna risorsa da server esterni** — font, immagini, script, tutto servito da `aimonx.app`. ⭐ **Dal giro W4 la causa è tolta** (`theme: null`, niente Primer, niente `cdnjs`) **e misurata a zero in due modi**: nella build e col browser vero. ⭐ **`WD26` è chiusa nel giro W7, sul sito vero:** 12 richieste, 0 esterne; ② ⛔ **dove passa il confine col militare lo decide Pier guardando**, non CC censurandosi prima: una scelta vicina al limite **si segnala e si fa vedere.**
- **`playwright`** — un browser **suo**, separato da quello di Pier: non tocca il suo profilo né le sue schede. ⚠️ **È un server MCP avviato con `npx`**, quindi arriva alla sessione **successiva** alla sua installazione; per una misura subito c'è `scripts/anteprima-playwright.mjs`, che usa lo stesso browser da riga di comando.

⛔ **Gli scartati NON si reinstallano senza chiederlo a Pier** — sono stati valutati, non dimenticati:

- **`typescript-lsp`** — il sito ha JS minimo. Si riprende **se arriva JavaScript vero.**
- **`Context7`** — dà la documentazione **più recente**, cioè Jekyll 4, ⛔ **mentre Pages costruisce con Jekyll 3.10**: la fonte giusta è la toolchain locale, che ha le versioni vere.
- **`code-review` + `security-guidance`** — i rischi veri del sito li coprono controprova, Playwright, Cowork e Pier. ⚠️ **Cowork aggiunge che su un repo pubblico le revisioni sarebbero pubbliche: è una sua ipotesi, non verificata qui.** Si riprendono quando ci sarà codice vero.
- **`GitHub`** — `gh` fa già tutto, e ⛔ **un token in più sarebbe una terza chiave** accanto alla separazione degli account provata nel giro W1.

## Regole operative

- I commenti nei file di lavoro sono parte del contratto con la specifica: citano il punto e spiegano vincoli non ovvi. Mantenerli aggiornati quando si cambia il comportamento.
- ⛔ **Il `§` indirizza SOLO `spec-sito.md`**, l'unico documento di questo progetto con sezioni numerate. La specifica dell'app si cita **per nome e sezione** (`prodotto.md §27.6`), e un punto di un documento di giro si cita **per nome**: `giro W0 §4`, `WA1`. *(Dall'app, `RD45`: le citazioni nude risolvevano su una sezione che non c'entra, e il guardrail non le vedeva.)*

## Vincoli non negoziabili

Non sono lo stato attuale del codice: sono impegni presi. Non si derogano senza una decisione esplicita di Pier.

- ⛔⛔ **L'indirizzo e il telefono di Pier NON vanno MAI online** — né sul sito, né nel repo, né nell'app. **È il MUST, e sta sopra ogni altra regola qui dentro**, compresa una norma che sembrasse chiederli: in quel caso ⛔ **la norma si risolve in un altro modo, o si chiede a Pier** (`…/8- AIMONX web/1- Specifiche/conformita-sito.md` §4, punto 1).
- ⛔ **AIMONX non vende armi: vende un'app per REGISTRARE le proprie armi.** È il perimetro con cui si legge tutto il resto: niente vendita di armi o munizioni, marketplace, community, classifiche, consigli legali, politica.
- ⛔ **Conformità Italia (principale), UE e USA.** La mappa delle norme che toccano il sito — GDPR, cookie, marchi Apple, WCAG, font — sta in `…/8- AIMONX web/1- Specifiche/conformita-sito.md`, ⚠️ **che vale come mappa e non come parere legale**, e marca «NON VERIFICATO» ciò che non lo è.
- **Local-first, e la parola va letta per intero.** Nessun server dello sviluppatore, nessun account obbligatorio, nessuna telemetria: **questo non cambia.** ⚠️ **Ma «i dati restano sul dispositivo dell'utente» ha smesso di essere vero il 27/07/2026:** una copia **cifrata** del diario sta **nell'iCloud dell'utente**, attiva di default e spegnibile (`~/Developer/AIMONX/docs/prodotto.md` §8.1, §10). ⛔ **Sul sito si dice questo** — un blocco cifrato, nello spazio iCloud dell'utente, nessun server e nessun accesso dello sviluppatore — **e mai «solo sul tuo iPhone»**, che sarebbe la promessa falsa di cui parlano le «Trappole». ⭐ **Il testo della landing lo dice già giusto:** `_data/landing.yml`, `privacy.note`.
- **Nessuna libreria di terze parti che comunichi in rete.** Prima di aggiungere una dipendenza: fermarsi e chiedere.
- **Tono sportivo e neutro, mai militare o aggressivo.** Vale per i testi dell'app, i commenti, i messaggi di commit e la scheda App Store.

**In più, per il sito:**

- **Il sito non promette niente che non stia in `~/Developer/AIMONX/docs/prodotto.md`.** Una promessa sul sito è pubblica: un'app che vende privacy non può avere un sito che dice il falso.
- **Nessun tracker, nessun analytics, nessun form che raccolga dati** senza una decisione esplicita di Pier, scritta in `spec-sito.md`.
- **Lingua primaria: inglese US scritto nativo.** L'italiano è secondario. Le parole dell'app sono quelle del catalogo testi.

## Trappole — sembrano miglioramenti, sono danni pubblici

- ⛔ **Un merge su `main` pubblica, ed è misurato.** Pages costruisce con Jekyll dalla radice di `main`, quindi un merge non è «salvare»: è mettere online. ⭐ **Ma la vecchia riga qui diceva che al merge `CLAUDE.md` sarebbe diventato `aimonx.app/CLAUDE.html`, e il giro W3 l'ha MISURATA E SMENTITA:** dopo il merge quell'indirizzo risponde `404`, perché `exclude` tiene (WD19, WD25). ⛔ **Il pericolo non è sparito, si è spostato:** non è più «il merge pubblica tutto», è **«il merge pubblica tutto ciò che `exclude` non nomina»** — e una lista di negazioni non nomina ciò che non esiste ancora. Nessun merge senza l'autorizzazione di Pier — e qui chi sbaglia lo vede il mondo, non un test.
- ⛔ **Il repo è PUBBLICO, e questo vale prima del merge e indipendentemente da lui.** Un `git push` di un ramo qualsiasi rende i file di lavoro leggibili su `github.com/aimonxapp/aimonx` da chiunque, merge o no. ⚠️ **I file vivi citano le cartelle di Pier in forma abbreviata** (`…/8- AIMONX web/…`): il nome della cartella, non il percorso intero. ⛔ **Il percorso intero non entra in nessun file tracciato** (WD17, deciso da Pier il 21/09/2026): sta in `.claude/settings.local.json` e in `scripts/percorsi-locali.sh`, che `.gitignore` tiene fuori — **e la controprova lo controlla a ogni giro.** **Nessun dato personale nei messaggi di commit, nessun file di lavoro di Pier nel repo** (`spec-sito.md` §1).
- ⛔ **Due account sul Mac, e confonderli è il modo di fare un casino con l'app.** Questo repo è di `aimonxapp`, quello dell'app di `Pier974`. ⭐ **L'isolamento è un credential helper LOCALE a questo repo** (`git config --local credential.https://github.com.helper`), che prende il token con `gh auth token --user aimonxapp`. ⛔ **Non si usa `gh auth switch`:** l'account attivo di `gh` è `Pier974` e serve all'app — cambiarlo firmerebbe `aimonxapp` anche i push dell'app. ⚠️ **Misurato:** `gh auth git-credential` serve **solo** l'account attivo e rifiuta se il nome chiesto è un altro.
- ⛔ **Un testo «migliorato» che dice più di quello che l'app fa** è la trappola del sito: la funzione promessa e non presente. Si verifica contro `~/Developer/AIMONX/docs/prodotto.md`, non contro la memoria.

**Se una modifica tocca una di queste quattro zone: fermati e chiedi, anche se la controprova passa.**

## Chi decide cosa — il criterio è cosa ciascuno può vedere

- **Claude Code vede il repo, il codice, git e i numeri.** Decide e scrive **il come**: sintassi, comandi, struttura dei file, misure. ⭐ **Se un giro ti dice come si fa una cosa nel repo e il come è sbagliato, non obbedire: correggi e dillo.**
- **Cowork vede Pier, le decisioni e il mondo fuori dal repo.** Scrive **l'intento** di ogni giro e le condizioni di stop, i vincoli che nel codice non esistono, e il lavoro di pubblicazione (privacy policy, App Store, DSA).
- ⛔ **Cowork non ti dice più come si fa una cosa nel repo:** scrive cosa deve essere vero alla fine e come si prova. **Ogni sua ipotesi su qualcosa che sta nel codice arriva etichettata come ipotesi** — verificala e riferisci, non darla per buona.
- ⛔ **I testi che l'utente legge li scrive Cowork.** Non per gerarchia: **non esiste un test che dica se una frase è chiara, o se il tono è sportivo invece che militare.** È l'unica zona senza controprova meccanica. **Se un giro richiede un testo nuovo per l'utente, fermati e riferisci.** ⚠️ **Qui vale il doppio:** in questo repo *tutto* ciò che si costruisce è testo che l'utente legge.
- ⛔ **Pier non scrive codice, e nessun criterio di scelta può misurarsi su quanto gli costi modificarlo.** ⚠️ **È stato scritto davvero, in `WD19`:** *«quanto costa a Pier cambiare un testo da solo»* — un costo che non è suo, quindi un criterio che non misura niente. ⭐ **I costi si misurano sul lavoro dei giri e sul rischio:** quante sessioni serve, e cosa succede se va storta.
- ⭐ **`CLAUDE.md` e i file del repo sono tuoi, questo blocco compreso.** Cowork consegna il testo, tu lo integri dove ha senso. **Aggiungere un puntatore a un file che hai appena creato è tuo diritto, non un'intrusione.**
- **Cosa è aperto sta in `docs/aperti.md`**, nel repo. ⛔ **Le voci gemelle restano aperte anche nel registro dell'app:** chiuderne una qui non chiude quella là, e il contrario nemmeno. Chi ne chiude una lo dice in `bacheca.md`.

## Regole di ramo

- ⛔ **Non si committa su `main`.** Ogni giro ha il suo ramo.
- ⛔ **Il merge su `main` lo autorizza Pier**, mai il giro che ha scritto il codice. **E qui il merge è una pubblicazione:** vedi «Trappole».
- **Non si cancella nulla:** i rami dei tentativi falliti si taggano e restano.

## Regola delle versioni

Il sito non ha versioni: ha ciò che è online. ⛔ Nessuna numerazione si inventa. ⚠️ `spec-sito.md` §8 prevede una pagina `aggiornamenti/`: quella è una **cronologia leggibile dall'utente**, con le date dei cambiamenti pubblicati, e ⛔ **non è una numerazione del sito.** Se servirà un numero, lo si propone allora.

## Verifica di fine giro

- `scripts/controprova.sh`.
- ⛔ **I numeri attesi non sono scritti qui: li misura lo script.** Un numero copiato a mano invecchia senza dirlo. I valori attesi stanno in `scripts/attese.txt`, e si aggiornano solo con `--aggiorna-attese`. ⭐ **E vale oltre le attese: un numero misurabile oggi non si scrive senza il comando che lo produce; se cambia a ogni commit, si scrive solo il comando.** ⚠️ **Non vale per i numeri al passato dentro un verbale:** quelli sono citazioni, non misure, e si tengono.
- **Il guardrail dei file vivi** è dentro la stessa controprova: tetto di righe per ciascuno, **nessuna data nei titoli `## `**, e ogni percorso citato che risolve. ⛔ **Se scatta il controllo delle date, un verbale è entrato in un file vivo: si guarda cos'è entrato prima di alzare il numero.**
- ⛔ **Un controllo che protesta sempre viene disattivato — è così che muoiono i guardrail.** Quindi si controlla che una misura **porti la sua prova**, non che sia ancora quella di ieri. ⭐ **E quando una misura non si può fare, il terzo esito è «non misurabile», dichiarato — non una soglia più larga.**
- ⛔ **La misura che conta è il sito vero, non il repo.** `curl` su `https://aimonx.app` dice cosa legge il mondo; il repo dice solo cosa è stato scritto. ⚠️ **Fra i due c'è la build di Pages**, che nessuno script locale esegue.
- ⭐ **I tre tetti sono due domande diverse.** `docs/aperti.md` è **append-only** — la regola 2 del registro tiene in tabella anche le voci chiuse, quindi chiudere non libera una riga — e lì lo sfondamento non chiede *«stai ingrassando?»* ma *«cosa è entrato: una regola o un verbale?»*, e dopo aver guardato la risposta giusta è quasi sempre alzarlo. Per `CLAUDE.md` e `docs/piano-chiusura.md` no: **quei due devono restare stabili**, e lì il tetto è un freno.
